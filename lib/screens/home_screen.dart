import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/screens/child_select.dart';
import 'package:babybuddy_app/screens/quick_add.dart';
import 'package:babybuddy_app/screens/about_screen.dart';
import 'package:babybuddy_app/screens/settings_screen.dart';
import 'package:babybuddy_app/screens/login_screen.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:babybuddy_app/utils/date_time_utils.dart';
import 'package:babybuddy_app/utils/timer_manager.dart';
import 'package:babybuddy_app/widgets/timer_card.dart';
import 'package:babybuddy_app/main.dart';
import 'package:babybuddy_app/generated/app_localizations.dart';
import 'package:babybuddy_app/generated/app_localizations_en.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List timeline = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedChildName;
  int? _selectedChildId;
  String? _serverUrl;
  bool _hasSelectedChild = false;
  List _timers = [];
  bool _quickReportEnabled = false;

  // ==================== 新增功能（参考官方原版 Android App）====================
  // 子页左右滑动切换
  final PageController _pageController = PageController(viewportFraction: 1);
  int _pageIndex = 0;
  List _allChildren = [];

  // 尿布一键速记栏
  bool _diaperWet = false;
  bool _diaperSolid = false;
  bool _savingDiaper = false;

  /// 保存 StreamSubscription，防止内存泄漏
  StreamSubscription<List<Map<String, dynamic>>>? _timersSubscription;

  /// 便捷获取当前语言包（保证非空，出问题用英文兜底 AppLocalizationsEn）
  AppLocalizations get l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsEn();

  @override
  void initState() {
    super.initState();
    loadSettings();
    loadTimeline();
    loadTimers();
  }

  @override
  void dispose() {
    _timersSubscription?.cancel();
    _timersSubscription = null;
    if (mounted) {
      try { _pageController.dispose(); } catch (_) {}
    }
    super.dispose();
  }

  // ============== 初始化 ==============

  Future<void> loadSettings() async {
    final quickReport = await Storage.getQuickReport(); // 返回非空 bool
    if (!mounted) return;
    setState(() {
      _quickReportEnabled = quickReport;
    });
  }

  Future<void> loadTimeline() async {
    final childId = await Storage.getChildId();

    if (childId == null) {
      if (mounted) {
        setState(() {
          _hasSelectedChild = false;
          _selectedChildName = null;
          _selectedChildId = null;
          timeline = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _hasSelectedChild = true;
      });
    }

    try {
      final results = await Future.wait([
        Storage.getServerUrl(),
        ApiService.getChildren(),
        ApiService.getTimeline(childId: childId),
      ]);
      final serverUrl = results[0] as String?;
      final children = results[1] as List;
      final data = results[2] as List;

      final selectedChild = children.cast<Map<String, dynamic>>().firstWhere(
            (c) => c['id'] == childId,
        orElse: () => {},
      );

      if (!mounted) return;

      if (selectedChild.isNotEmpty) {
        setState(() {
          _selectedChildName =
          '${selectedChild['first_name'] ?? ''} ${selectedChild['last_name'] ?? ''}'
              .trim();
          _selectedChildId = childId;
        });
      }
      setState(() {
        _serverUrl = serverUrl;
        timeline = data;
        _allChildren = children;
      });
      // 同步 PageView 到当前选中 child 的 index
      _syncPageToSelected(childId, children);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        Fluttertoast.showToast(
          msg: '${l10n.loadTimelineFailed}: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> loadTimers() async {
    final childId = await Storage.getChildId();
    if (childId == null) return;

    try {
      await TimerManager().loadTimers(childId: childId);
      // 先设置一次当前快照，避免首帧空
      if (mounted) {
        setState(() => _timers = TimerManager().timers);
      }
      // 先取消可能存在的旧订阅
      await _timersSubscription?.cancel();
      _timersSubscription =
          TimerManager().timersStream.listen((timers) {
            if (mounted) {
              setState(() => _timers = timers);
            }
          });
    } catch (e) {
      debugPrint('加载定时器失败: $e');
    }
  }

  // ============== 功能操作 ==============

  Future<void> createTimer() async {
    if (_selectedChildId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
      return;
    }
    try {
      await TimerManager().createTimer(childId: _selectedChildId);
      if (mounted) Fluttertoast.showToast(msg: l10n.timerStarted);
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: '${l10n.startTimerFailed}: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  /// 复制宝宝详情页链接到剪贴板（原 _openInBrowser 名不副实）
  void _copyBabyLink() {
    if (_serverUrl == null || _selectedChildId == null) {
      Fluttertoast.showToast(msg: l10n.cannotOpenUrl);
      return;
    }
    final url = '$_serverUrl/child/$_selectedChildId/';
    Clipboard.setData(ClipboardData(text: url));
    Fluttertoast.showToast(msg: '${l10n.linkCopied}:\n$url');
  }

  // ==================== PageView（左右滑动切换多宝宝）====================

  void _syncPageToSelected(int childId, List children) {
    if (children.isEmpty) return;
    int idx = 0;
    for (int i = 0; i < children.length; i++) {
      final c = children[i];
      if (c is Map && c['id'] == childId) { idx = i; break; }
    }
    _pageIndex = idx;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      if (_pageController.page?.round() != idx) {
        _pageController.animateToPage(
          idx,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _switchToChildByIndex(int idx) async {
    final list = _allChildren;
    if (idx < 0 || idx >= list.length) return;
    final c = list[idx];
    if (c is! Map) return;
    final id = c['id'];
    if (id is! int) return;
    if (id == _selectedChildId) return;
    setState(() => _pageIndex = idx);
    await Storage.saveChildId(id);
    // 切换后触发重新拉 timeline + timers
    await loadTimeline();
    await loadTimers();
    // 切换宝宝清空尿布速记状态
    setState(() { _diaperWet = false; _diaperSolid = false; });
  }

  // ==================== 尿布一键速记栏（参考原版 App 的两键速记）====================

  Widget _buildQuickDiaperBar() {
    if (!_hasSelectedChild) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final wetSelected = _diaperWet;
    final solidSelected = _diaperSolid;
    final hasAny = wetSelected || solidSelected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      height: hasAny ? 132 : 88,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DiaperQuickButton(
                  icon: Icons.water_drop_outlined,
                  activeIcon: Icons.water_drop,
                  label: l10n.wet,
                  selected: wetSelected,
                  activeColor: scheme.tertiary,
                  onTap: () => setState(() => _diaperWet = !_diaperWet),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DiaperQuickButton(
                  icon: Icons.breakfast_dining_outlined,
                  activeIcon: Icons.breakfast_dining,
                  label: l10n.solid,
                  selected: solidSelected,
                  activeColor: Colors.brown,
                  onTap: () => setState(() => _diaperSolid = !_diaperSolid),
                ),
              ),
            ],
          ),
          if (hasAny) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() { _diaperWet = false; _diaperSolid = false; }),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _savingDiaper ? null : _saveQuickDiaper,
                    icon: _savingDiaper
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_savingDiaper ? '…' : '${l10n.diaper} ✓'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveQuickDiaper() async {
    final childId = _selectedChildId;
    if (childId == null || (!_diaperWet && !_diaperSolid)) return;
    setState(() => _savingDiaper = true);
    try {
      final now = DateTime.now();
      final time = DateTimeUtils.formatForApi(now);
      // 默认颜色：只 Wet → 未知；有 Solid → Other（用户可之后编辑）
      String color = '';
      if (_diaperSolid) {
        color = _getDiaperColorKey(l10n.other) ?? 'other';
      } else {
        color = _getDiaperColorKey(l10n.unknown) ?? 'unknown';
      }
      await ApiService.addDiaper(childId, time, _diaperWet, _diaperSolid, color);
      if (mounted) {
        Fluttertoast.showToast(
          msg: '${l10n.diaper} ✓',
          backgroundColor: Colors.green,
        );
        setState(() { _diaperWet = false; _diaperSolid = false; });
        await loadTimeline();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '保存失败: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _savingDiaper = false);
    }
  }

  String? _getDiaperColorKey(String label) {
    if (label == l10n.yellow) return 'yellow';
    if (label == l10n.brown) return 'brown';
    if (label == l10n.green) return 'green';
    if (label == l10n.unknown) return 'unknown';
    if (label == l10n.other) return 'other';
    return null;
  }

  // ==================== 重建默认定时器 ====================

  Future<void> _recreateDefaultTimersAction() async {
    final childId = _selectedChildId;
    final name = _selectedChildName ?? '';
    if (childId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.restart_alt_outlined),
        title: const Text('重建默认定时器'),
        content: Text(
          name.isEmpty
              ? '将清除当前所有计时器并重新创建 Feeding / Sleep / Tummy Time 三个默认计时器。是否继续？'
              : '将清除 $name 的所有计时器并重新创建 Feeding / Sleep / Tummy Time 三个默认计时器（与 Baby Buddy 官方原版 Android App 相同行为）。是否继续？',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('重建')),
        ],
      ),
    );
    if (ok != true) return;

    Fluttertoast.showToast(msg: '正在重建…');
    try {
      await ApiService.recreateDefaultTimers(childId);
      await loadTimers();
      if (mounted) Fluttertoast.showToast(msg: '默认定时器已重建', backgroundColor: Colors.green);
    } catch (e) {
      Fluttertoast.showToast(msg: '重建失败: $e', backgroundColor: Colors.red, toastLength: Toast.LENGTH_LONG);
    }
  }

  // ==================== 长按 Timeline 记录 → 打开服务器网页 ====================

  Future<void> _openRecordInBrowser(dynamic item) async {
    if (_serverUrl == null || _serverUrl!.isEmpty) return;
    final id = item['id'];
    if (id == null) return;
    final model = item['model']?.toString() ?? '';
    final path = _recordPathFragment(model);
    if (path == null) {
      Fluttertoast.showToast(msg: '该类型暂不支持在网页打开');
      return;
    }
    final url = '$_serverUrl/$path/$id/change/';
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Fluttertoast.showToast(msg: '无法打开浏览器: $e', backgroundColor: Colors.red);
    }
  }

  String? _recordPathFragment(String model) {
    switch (model) {
      case 'sleep': return 'sleep';
      case 'feeding': return 'feeding';
      case 'change': return 'change';
      case 'tummy time': return 'tummy-time';
      case 'pumping': return 'pumping';
      case 'note': return 'notes';
      case 'weight': return 'weight';
      case 'height': return 'height';
      case 'head circumference': return 'head-circumference';
      case 'temperature': return 'temperature';
      default: return null;
    }
  }

  Future<void> logout() async {
    await Storage.logout();
    if (!mounted) return;
    // 清空整个导航栈，返回登录页
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  Future<void> deleteRecord(dynamic item) async {
    final model = item['model']?.toString() ?? '';
    final id = item['id'];

    if (id == null) {
      Fluttertoast.showToast(msg: '无法删除：记录ID不存在');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(l10n.confirmDelete),
            content: Text(l10n.confirmDeleteRecord),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      switch (model) {
        case 'sleep':
          await ApiService.deleteSleep(id);
          break;
        case 'feeding':
          await ApiService.deleteFeeding(id);
          break;
        case 'change':
          await ApiService.deleteDiaper(id);
          break;
        case 'note':
          await ApiService.deleteNote(id);
          break;
        case 'tummy time':
          await ApiService.deleteTummyTime(id);
          break;
        case 'pumping':
          await ApiService.deletePumping(id);
          break;
        case 'weight':
          await ApiService.deleteWeight(id);
          break;
        case 'height':
          await ApiService.deleteHeight(id);
          break;
        case 'head circumference':
          await ApiService.deleteHeadCircumference(id);
          break;
        case 'temperature':
          await ApiService.deleteTemperature(id);
          break;
        default:
          Fluttertoast.showToast(msg: l10n.typeNotSupportedDelete);
          return;
      }
      Fluttertoast.showToast(msg: l10n.deleteSuccess);
      await loadTimeline();
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: '删除失败: $e',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============== 记录显示辅助方法 ==============

  String _getRecordTitle(dynamic item) {
    final model = item['model']?.toString() ?? '';
    switch (model) {
      case 'sleep': return l10n.sleep;
      case 'feeding': return l10n.feeding;
      case 'change': return l10n.diaper;
      case 'tummy time': return l10n.tummyTime;
      case 'pumping': return l10n.pumping;
      case 'note': return l10n.note;
      case 'weight': return l10n.weight;
      case 'height': return l10n.height;
      case 'head circumference': return l10n.headCircumference;
      case 'temperature': return l10n.temperature;
      default: return model;
    }
  }

  IconData _getRecordIcon(dynamic item) {
    switch (item['model']?.toString() ?? '') {
      case 'sleep': return Icons.bedtime;
      case 'feeding': return Icons.restaurant;
      case 'change': return Icons.baby_changing_station;
      case 'tummy time': return Icons.self_improvement;
      case 'pumping': return Icons.water_drop;
      case 'note': return Icons.note;
      case 'weight':
      case 'height':
      case 'head circumference':
        return Icons.monitor_weight;
      case 'temperature': return Icons.thermostat;
      default: return Icons.event;
    }
  }

  Color _getRecordColor(dynamic item) {
    switch (item['model']?.toString() ?? '') {
      case 'sleep': return Colors.blue;
      case 'feeding': return Colors.orange;
      case 'change': return Colors.yellow[700]!;
      case 'tummy time': return Colors.green;
      case 'pumping': return Colors.purple;
      case 'note': return Colors.teal;
      case 'weight':
      case 'height':
      case 'head circumference':
        return Colors.deepPurple;
      case 'temperature': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatTime(String timeStr) => DateTimeUtils.formatDisplayTime(timeStr);

  String _getRecordBrief(dynamic item) {
    final model = item['model']?.toString() ?? '';
    switch (model) {
      case 'sleep':
        final nap = item['nap'] == true;
        final duration = item['duration'];
        return '${nap ? l10n.nap : l10n.sleeping}${duration != null ? " ($duration)" : ""}';
      case 'feeding':
        final method = item['method'];
        final type = item['type'];
        final amount = item['amount'];
        String brief = '';
        if (type != null) brief += _getFeedingTypeName(type);
        if (method != null) brief += ' - ${_getFeedingMethodName(method)}';
        if (amount != null) brief += ' ($amount ml)';
        return brief;
      case 'change':
        final wet = item['wet'] == true;
        final solid = item['solid'] == true;
        String result = '';
        if (wet) result += l10n.wet;
        if (solid) result += (result.isEmpty ? l10n.solid : '+${l10n.solid}');
        return result.isEmpty ? l10n.unknown : result;
      case 'pumping':
        final amount = item['amount'];
        return amount != null ? '$amount ml' : '';
      case 'note':
        final note = item['note']?.toString() ?? '';
        return note.length > 30 ? '${note.substring(0, 30)}...' : note;
      default:
        return '';
    }
  }

  String _getRecordDetail(dynamic item) {
    final model = item['model']?.toString() ?? '';
    final buffer = StringBuffer();

    switch (model) {
      case 'sleep':
        final nap = item['nap'] == true;
        final duration = item['duration'];
        final start = item['start'];
        final end = item['end'];
        final notes = item['notes'];
        buffer.writeln('${l10n.type}: ${nap ? l10n.nap : l10n.sleeping}');
        if (duration != null) buffer.writeln('${l10n.duration}: $duration');
        if (start != null) buffer.writeln('${l10n.startTime}: ${_formatTime(start)}');
        if (end != null) buffer.writeln('${l10n.endTime}: ${_formatTime(end)}');
        if (notes != null && notes.toString().isNotEmpty) buffer.writeln('${l10n.notes}: $notes');
        break;
      case 'feeding':
        final method = item['method'];
        final type = item['type'];
        final amount = item['amount'];
        final start = item['start'];
        final end = item['end'];
        final notes = item['notes'];
        if (type != null) buffer.writeln('${l10n.milkType}: ${_getFeedingTypeName(type)}');
        if (method != null) buffer.writeln('${l10n.feedingMethod}: ${_getFeedingMethodName(method)}');
        if (amount != null) buffer.writeln('${l10n.amount}: $amount ml');
        if (start != null) buffer.writeln('${l10n.startTime}: ${_formatTime(start)}');
        if (end != null) buffer.writeln('${l10n.endTime}: ${_formatTime(end)}');
        if (notes != null && notes.toString().isNotEmpty) buffer.writeln('${l10n.notes}: $notes');
        break;
      case 'change':
        final wet = item['wet'] == true;
        final solid = item['solid'] == true;
        final color = item['color'];
        final time = item['time'];
        final notes = item['notes'];
        buffer.writeln('${l10n.type}: ${wet ? l10n.wet : ""}${solid ? (wet ? "+${l10n.solid}" : l10n.solid) : ""}');
        if (color != null && color != 'unknown') buffer.writeln('${l10n.color}: ${_getDiaperColorName(color)}');
        if (time != null) buffer.writeln('${l10n.time}: ${_formatTime(time)}');
        if (notes != null && notes.toString().isNotEmpty) buffer.writeln('${l10n.notes}: $notes');
        break;
      case 'pumping':
        final amount = item['amount'];
        final start = item['start'];
        final end = item['end'];
        final notes = item['notes'];
        if (amount != null) buffer.writeln('${l10n.amount}: $amount ml');
        if (start != null) buffer.writeln('${l10n.startTime}: ${_formatTime(start)}');
        if (end != null) buffer.writeln('${l10n.endTime}: ${_formatTime(end)}');
        if (notes != null && notes.toString().isNotEmpty) buffer.writeln('${l10n.notes}: $notes');
        break;
      case 'note':
        final note = item['note'];
        final time = item['time'];
        if (note != null) buffer.writeln('${l10n.content}: $note');
        if (time != null) buffer.writeln('${l10n.time}: ${_formatTime(time)}');
        break;
      case 'tummy time':
        final duration = item['duration'];
        final start = item['start'];
        final end = item['end'];
        final milestone = item['milestone'];
        if (duration != null) buffer.writeln('${l10n.duration}: $duration');
        if (start != null) buffer.writeln('${l10n.startTime}: ${_formatTime(start)}');
        if (end != null) buffer.writeln('${l10n.endTime}: ${_formatTime(end)}');
        if (milestone != null && milestone.toString().isNotEmpty) buffer.writeln('${l10n.milestone}: $milestone');
        break;
      case 'weight':
        final weight = item['weight'];
        final date = item['date'];
        if (weight != null) buffer.writeln('${l10n.weightKg}: $weight kg');
        if (date != null) buffer.writeln('${l10n.date}: $date');
        break;
      case 'height':
        final height = item['height'];
        final date = item['date'];
        if (height != null) buffer.writeln('${l10n.heightCm}: $height cm');
        if (date != null) buffer.writeln('${l10n.date}: $date');
        break;
      case 'head circumference':
        final circumference = item['circumference'];
        final date = item['date'];
        if (circumference != null) buffer.writeln('${l10n.headCircumferenceCm}: $circumference cm');
        if (date != null) buffer.writeln('${l10n.date}: $date');
        break;
      case 'temperature':
        final temp = item['temperature'];
        final time = item['time'];
        if (temp != null) buffer.writeln('${l10n.temperatureC}: $temp °C');
        if (time != null) buffer.writeln('${l10n.time}: ${_formatTime(time)}');
        break;
    }
    return buffer.toString().trim();
  }

  String _getFeedingTypeName(String type) {
    const types = {
      'breast milk': 'breastMilk',
      'formula': 'formula',
      'fortified breast milk': 'fortifiedBreastMilk',
      'pumped milk': 'pumpedMilk',
    };
    final key = types[type];
    if (key == null) return type;
    return _lookupL10n(key) ?? type;
  }

  String _getFeedingMethodName(String method) {
    const methods = {
      'left breast': 'leftBreast',
      'right breast': 'rightBreast',
      'both breasts': 'bothBreasts',
      'bottle': 'bottle',
      'spoon': 'spoon',
    };
    final key = methods[method];
    if (key == null) return method;
    return _lookupL10n(key) ?? method;
  }

  String _getDiaperColorName(String color) {
    const colors = {
      'unknown': 'unknown',
      'yellow': 'yellow',
      'brown': 'brown',
      'green': 'green',
      'other': 'other',
    };
    final key = colors[color];
    if (key == null) return color;
    return _lookupL10n(key) ?? color;
  }

  /// 按属性名动态查找当前 l10n 的字段（简化 switch 重复代码）
  String? _lookupL10n(String name) {
    final AppLocalizations local = l10n;
    switch (name) {
      // -------- Feeding type --------
      case 'breastMilk': return local.breastMilk;
      case 'formula': return local.formula;
      case 'fortifiedBreastMilk': return local.fortifiedBreastMilk;
      case 'pumpedMilk': return local.pumpedMilk;
      // -------- Feeding method --------
      case 'leftBreast': return local.leftBreast;
      case 'rightBreast': return local.rightBreast;
      case 'bothBreasts': return local.bothBreasts;
      case 'bottle': return local.bottle;
      case 'spoon': return local.spoon;
      // -------- Diaper color --------
      case 'unknown': return local.unknown;
      case 'yellow': return local.yellow;
      case 'brown': return local.brown;
      case 'green': return local.green;
      case 'other': return local.other;
      default: return null;
    }
  }

  // ============== 主界面 ==============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'select_child',
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(l10n.selectChild),
                ),
              ),
              PopupMenuItem<String>(
                value: 'recreate_default_timers',
                enabled: _hasSelectedChild,
                child: ListTile(
                  leading: const Icon(Icons.restart_alt_outlined),
                  title: const Text('重建默认定时器'),
                  subtitle: const Text('Feeding / Sleep / Tummy Time'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'copy_baby_link',
                enabled: _hasSelectedChild,
                child: ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('复制宝宝链接'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text(l10n.settings),
                ),
              ),
              PopupMenuItem<String>(
                value: 'about',
                child: ListTile(leading: const Icon(Icons.info), title: Text(l10n.about)),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _hasSelectedChild
          ? FloatingActionButton(
        onPressed: () {
          if (_quickReportEnabled) {
            _showQuickReportOptions();
          } else {
            _showAddMenu();
          }
        },
        child: const Icon(Icons.add),
      )
          : null,
      body: RefreshIndicator(
        onRefresh: loadTimeline,
        child: _buildBody(),
      ),
    );
  }

  Future<void> _onMenuSelected(String value) async {
    switch (value) {
      case 'select_child':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChildSelect()),
        );
        loadTimeline();
        loadTimers();
        break;
      case 'recreate_default_timers':
        await _recreateDefaultTimersAction();
        break;
      case 'copy_baby_link':
        _copyBabyLink();
        break;
      case 'settings':
        final appState = MyApp.of(context);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SettingsScreen(
                  onThemeChanged: () async {
                    final mode = await Storage.getThemeMode();
                    if (mounted) {
                      appState?.updateThemeMode(mode);
                    }
                  },
                ),
          ),
        );
        loadSettings();
        break;
      case 'about':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        );
        break;
      case 'logout':
        logout();
        break;
    }
  }

  Widget _buildBody() {
    if (!_hasSelectedChild) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              l10n.noChildSelected,
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.clickMenuSelectChild,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChildSelect()),
                );
                loadTimeline();
              },
              icon: const Icon(Icons.person),
              label: Text(l10n.selectChild),
            ),
          ],
        ),
      );
    }

    if (_isLoading && timeline.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && timeline.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              l10n.loadFailed,
              style: TextStyle(fontSize: 18, color: Colors.red[300]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: loadTimeline, child: Text(l10n.reload)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildQuickDiaperBar(),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: (_allChildren.length > 1) ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
            onPageChanged: _switchToChildByIndex,
            itemCount: _allChildren.isEmpty ? 1 : _allChildren.length,
            itemBuilder: (ctx, idx) => Column(
              key: ValueKey('child-page-$idx-${_allChildren.isNotEmpty ? _allChildren[idx]['id'] ?? idx : idx}'),
              children: [
                _buildBabyInfoCard(),
                if (_timers.isNotEmpty) ..._buildTimersList(),
                Expanded(child: _buildTimelineList()),
              ],
            ),
          ),
        ),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildPageIndicator() {
    final count = _allChildren.isEmpty ? 0 : _allChildren.length;
    if (count <= 1) return const SizedBox(height: 10);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == _pageIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBabyInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _selectedChildName != null && _selectedChildName!.isNotEmpty
                      ? _selectedChildName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentBaby,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      _selectedChildName ?? l10n.notSelected,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: l10n.clickCopyLink,
                onPressed: _copyBabyLink,
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onLongPress: _copyBabyLink,
            child: Text(
              l10n.longPressCopyLink,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimersList() {
    return _timers
        .map((timer) =>
        TimerCard(
          timer: timer,
          selectedChildId: _selectedChildId,
          onTimerStopped: () => loadTimeline(),
          onTimerUsed: () => loadTimeline(),
        ))
        .toList();
  }

  Widget _buildTimelineList() {
    if (timeline.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noRecords,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.clickAddRecord,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: timeline.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (c, i) => _buildRecordCard(timeline[i]),
    );
  }

  Widget _buildRecordCard(dynamic item) {
    final theme = Theme.of(context);
    final color = _getRecordColor(item);
    final icon = _getRecordIcon(item);
    final title = _getRecordTitle(item);
    final brief = _getRecordBrief(item);
    final timeStr = item['time'] ?? item['start'] ?? item['date'] ?? '';
    final time = _formatTime(timeStr.toString());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onLongPress: () => _openRecordInBrowser(item),
        borderRadius: Theme.of(context).cardTheme.shape is RoundedRectangleBorder
            ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).borderRadius
            : BorderRadius.circular(12),
        child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (brief.isNotEmpty)
              Text(
                brief,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            Text(
              time,
              style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getRecordDetail(item), style: const TextStyle(fontSize: 14, height: 1.5)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final childId = await Storage.getChildId();
                        if (childId != null && mounted) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuickAdd(editItem: item, childId: childId),
                            ),
                          );
                          loadTimeline();
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(l10n.edit),
                    ),
                    TextButton.icon(
                      onPressed: () => deleteRecord(item),
                      icon: const Icon(Icons.delete, size: 18),
                      label: Text(l10n.delete),
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
          ),
        ),  // ExpansionTile
      ),   // InkWell
    );
  }

  // ============== 新增记录菜单 ==============

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: Text(l10n.startTimer),
                  onTap: () async {
                    Navigator.pop(context);
                    await createTimer();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(l10n.addRecord),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuickAdd()),
                    );
                    loadTimeline();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showQuickReportOptions() {
    final childId = _selectedChildId;
    if (childId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) =>
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.quickReport,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    children: [
                      _QuickReportButton(
                        icon: Icons.restaurant,
                        label: l10n.feeding,
                        color: Colors.orange,
                        onTap: () => _navigateQuickAdd('feeding', childId),
                      ),
                      _QuickReportButton(
                        icon: Icons.bedtime,
                        label: l10n.sleep,
                        color: Colors.blue,
                        onTap: () => _navigateQuickAdd('sleep', childId),
                      ),
                      _QuickReportButton(
                        icon: Icons.baby_changing_station,
                        label: l10n.diaper,
                        color: Colors.amber,
                        onTap: () => _navigateQuickAdd('change', childId),
                      ),
                      _QuickReportButton(
                        icon: Icons.self_improvement,
                        label: l10n.tummyTime,
                        color: Colors.green,
                        onTap: () => _navigateQuickAdd('tummy_time', childId),
                      ),
                      _QuickReportButton(
                        icon: Icons.water_drop,
                        label: l10n.pumping,
                        color: Colors.purple,
                        onTap: () => _navigateQuickAdd('pumping', childId),
                      ),
                      _QuickReportButton(
                        icon: Icons.edit_note,
                        label: l10n.note,
                        color: Colors.teal,
                        onTap: () => _navigateQuickAdd('note', childId),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddMenu();
                  },
                  icon: const Icon(Icons.more_horiz),
                  label: Text(l10n.moreOptions),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _navigateQuickAdd(String type, int childId) async {
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuickAdd(initialType: type, childId: childId),
      ),
    );
    loadTimeline();
  }
}

// ============== 子组件 ==============

class _QuickReportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickReportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 辅助组件：尿布一键速记按钮 ====================

class _DiaperQuickButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _DiaperQuickButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected ? activeColor : theme.colorScheme.outlineVariant;
    final bg = selected
        ? activeColor.withOpacity(0.12)
        : theme.colorScheme.surfaceContainerLow;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                color: selected ? activeColor : theme.colorScheme.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeColor : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



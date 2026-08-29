import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  /// 保存 StreamSubscription，防止内存泄漏
  StreamSubscription<List<Map<String, dynamic>>>? _timersSubscription;

  /// 便捷获取当前语言包（保证非空，出问题用英文兜底）
  AppLocalizations get l10n =>
      AppLocalizations.of(context) ?? _EnglishFallbackLocalizations();

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
      });
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
        _buildBabyInfoCard(),
        if (_timers.isNotEmpty) ..._buildTimersList(),
        Expanded(child: _buildTimelineList()),
      ],
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

// ============== 兜底 l10n（极少数情况下系统还没加载好本地化才会使用） ==============

class _EnglishFallbackLocalizations implements AppLocalizations {
  @override String get appTitle => 'Baby Buddy';
  @override String get sleep => 'Sleep';
  @override String get feeding => 'Feeding';
  @override String get diaper => 'Diaper';
  @override String get tummyTime => 'Tummy Time';
  @override String get pumping => 'Pumping';
  @override String get note => 'Note';
  @override String get weight => 'Weight';
  @override String get height => 'Height';
  @override String get headCircumference => 'Head Circumference';
  @override String get temperature => 'Temperature';
  @override String get noChildSelected => 'No child selected';
  @override String get clickMenuSelectChild => 'Click the menu to select a child';
  @override String get selectChild => 'Select Child';
  @override String get settings => 'Settings';
  @override String get about => 'About';
  @override String get logout => 'Logout';
  @override String get startTimer => 'Start Timer';
  @override String get addRecord => 'Add Record';
  @override String get quickReport => 'Quick Report';
  @override String get moreOptions => 'More Options';
  @override String get timerStarted => 'Timer started';
  @override String get startTimerFailed => 'Failed to start timer';
  @override String get cannotOpenUrl => 'Cannot copy link, please select a child first';
  @override String get linkCopied => 'Link copied to clipboard';
  @override String get loadFailed => 'Failed to load';
  @override String get reload => 'Reload';
  @override String get noRecords => 'No records yet';
  @override String get clickAddRecord => 'Click + to add a record';
  @override String get confirmDelete => 'Confirm Delete';
  @override String get confirmDeleteRecord => 'Are you sure you want to delete this record?';
  @override String get cancel => 'Cancel';
  @override String get delete => 'Delete';
  @override String get deleteSuccess => 'Deleted successfully';
  @override String get typeNotSupportedDelete => 'This type does not support deletion';
  @override String get edit => 'Edit';
  @override String get currentBaby => 'Current Baby';
  @override String get notSelected => 'Not Selected';
  @override String get clickCopyLink => 'Click to copy link';
  @override String get longPressCopyLink => 'Long press or icon to copy link';
  @override String get loadTimelineFailed => 'Failed to load timeline';
  @override String get nap => 'Nap';
  @override String get sleeping => 'Sleeping';
  @override String get duration => 'Duration';
  @override String get startTime => 'Start';
  @override String get endTime => 'End';
  @override String get notes => 'Notes';
  @override String get type => 'Type';
  @override String get milkType => 'Milk Type';
  @override String get feedingMethod => 'Feeding Method';
  @override String get amount => 'Amount';
  @override String get time => 'Time';
  @override String get color => 'Color';
  @override String get wet => 'Wet';
  @override String get solid => 'Solid';
  @override String get unknown => 'Unknown';
  @override String get content => 'Content';
  @override String get milestone => 'Milestone';
  @override String get weightKg => 'Weight';
  @override String get date => 'Date';
  @override String get heightCm => 'Height';
  @override String get headCircumferenceCm => 'Head Circumference';
  @override String get temperatureC => 'Temperature';
  @override String get breastMilk => 'Breast Milk';
  @override String get formula => 'Formula';
  @override String get fortifiedBreastMilk => 'Fortified Breast Milk';
  @override String get pumpedMilk => 'Pumped Milk';
  @override String get leftBreast => 'Left Breast';
  @override String get rightBreast => 'Right Breast';
  @override String get bothBreasts => 'Both Breasts';
  @override String get bottle => 'Bottle';
  @override String get spoon => 'Spoon';
  @override String get yellow => 'Yellow';
  @override String get brown => 'Brown';
  @override String get green => 'Green';
  @override String get other => 'Other';

  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

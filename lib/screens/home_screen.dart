import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/screens/child_select.dart';
import 'package:babybuddy_app/screens/quick_add.dart';
import 'package:babybuddy_app/screens/about_screen.dart';
import 'package:babybuddy_app/screens/settings_screen.dart';
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

  @override
  void initState() {
    super.initState();
    loadSettings();
    loadTimeline();
    loadTimers();
  }

  Future<void> loadSettings() async {
    final quickReport = await Storage.getQuickReport();
    setState(() {
      _quickReportEnabled = quickReport!;
    });
  }

  Future<void> loadTimeline() async {
    final childId = await Storage.getChildId();

    if (childId == null) {
      setState(() {
        _hasSelectedChild = false;
        _selectedChildName = null;
        _selectedChildId = null;
        timeline = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSelectedChild = true;
    });

    try {
      final serverUrl = await Storage.getServerUrl();
      final children = await ApiService.getChildren();
      final selectedChild = children.firstWhere(
        (c) => c['id'] == childId,
        orElse: () => null,
      );

      if (selectedChild != null) {
        setState(() {
          _selectedChildName = '${selectedChild['first_name'] ?? ''} ${selectedChild['last_name'] ?? ''}'.trim();
          _selectedChildId = childId;
        });
      }

      setState(() => _serverUrl = serverUrl);

      final data = await ApiService.getTimeline(childId: childId);
      setState(() => timeline = data);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (mounted) {
        Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.loadTimelineFailed ?? '加载时间线失败'}: $e');
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
      TimerManager().timersStream.listen((timers) {
        if (mounted) {
          setState(() => _timers = timers);
        }
      });
    } catch (e) {
      print('加载定时器失败: $e');
    }
  }

  Future<void> createTimer() async {
    if (_selectedChildId == null) {
      Fluttertoast.showToast(msg: AppLocalizations.of(context)?.noChildSelected ?? '请先选择宝宝');
      return;
    }

    try {
      await TimerManager().createTimer(childId: _selectedChildId);
      if (mounted) {
        Fluttertoast.showToast(msg: AppLocalizations.of(context)?.timerStarted ?? '定时器已启动');
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.startTimerFailed ?? '启动定时器失败'}: $e');
      }
    }
  }

  void _openInBrowser() {
    if (_serverUrl == null || _selectedChildId == null) {
      Fluttertoast.showToast(msg: AppLocalizations.of(context)?.cannotOpenUrl ?? '无法打开网页，请先选择宝宝');
      return;
    }
    final url = '$_serverUrl/child/$_selectedChildId/';
    Clipboard.setData(ClipboardData(text: url));
    Fluttertoast.showToast(msg: '${AppLocalizations.of(context)?.linkCopied ?? '链接已复制到剪贴板'}:\n$url');
  }

  Future<void> logout() async {
    await Storage.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
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
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.confirmDelete ?? '确认删除'),
        content: Text(AppLocalizations.of(context)?.confirmDeleteRecord ?? '确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)?.cancel ?? '取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)?.delete ?? '删除',
              style: const TextStyle(color: Colors.red),
            ),
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
          Fluttertoast.showToast(msg: AppLocalizations.of(context)?.typeNotSupportedDelete ?? '该类型暂不支持删除');
          return;
      }
      Fluttertoast.showToast(msg: AppLocalizations.of(context)?.deleteSuccess ?? '删除成功');
      await loadTimeline();
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: '删除失败: $e', backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getRecordTitle(dynamic item) {
    final l10n = AppLocalizations.of(context)!;
    final model = item['model']?.toString() ?? '';
    switch (model) {
      case 'sleep':
        return l10n.sleep;
      case 'feeding':
        return l10n.feeding;
      case 'change':
        return l10n.diaper;
      case 'tummy time':
        return l10n.tummyTime;
      case 'pumping':
        return l10n.pumping;
      case 'note':
        return l10n.note;
      case 'weight':
        return l10n.weight;
      case 'height':
        return l10n.height;
      case 'head circumference':
        return l10n.headCircumference;
      case 'temperature':
        return l10n.temperature;
      default:
        return model;
    }
  }

  IconData _getRecordIcon(dynamic item) {
    final model = item['model']?.toString() ?? '';
    switch (model) {
      case 'sleep':
        return Icons.bedtime;
      case 'feeding':
        return Icons.restaurant;
      case 'change':
        return Icons.baby_changing_station;
      case 'tummy time':
        return Icons.self_improvement;
      case 'pumping':
        return Icons.water_drop;
      case 'note':
        return Icons.note;
      case 'weight':
      case 'height':
      case 'head circumference':
        return Icons.monitor_weight;
      case 'temperature':
        return Icons.thermostat;
      default:
        return Icons.event;
    }
  }

  Color _getRecordColor(dynamic item) {
    final model = item['model']?.toString() ?? '';
    switch (model) {
      case 'sleep':
        return Colors.blue;
      case 'feeding':
        return Colors.orange;
      case 'change':
        return Colors.yellow[700]!;
      case 'tummy time':
        return Colors.green;
      case 'pumping':
        return Colors.purple;
      case 'note':
        return Colors.teal;
      case 'weight':
      case 'height':
      case 'head circumference':
        return Colors.deepPurple;
      case 'temperature':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(String timeStr) {
    return DateTimeUtils.formatDisplayTime(timeStr);
  }

  String _getRecordBrief(dynamic item) {
    final l10n = AppLocalizations.of(context)!;
    final model = item['model']?.toString() ?? '';
    switch (model) {
      case 'sleep':
        final nap = item['nap'] == true;
        final duration = item['duration'];
        return '${nap ? l10n.nap : l10n.sleeping} ${duration != null ? "($duration)" : ""}';
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
    final l10n = AppLocalizations.of(context)!;
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
    final l10n = AppLocalizations.of(context)!;
    final types = {
      'breast milk': l10n.breastMilk,
      'formula': l10n.formula,
      'fortified breast milk': l10n.fortifiedBreastMilk,
      'pumped milk': l10n.pumpedMilk,
    };
    return types[type] ?? type;
  }

  String _getFeedingMethodName(String method) {
    final l10n = AppLocalizations.of(context)!;
    final methods = {
      'left breast': l10n.leftBreast,
      'right breast': l10n.rightBreast,
      'both breasts': l10n.bothBreasts,
      'bottle': l10n.bottle,
      'spoon': l10n.spoon,
    };
    return methods[method] ?? method;
  }

  String _getDiaperColorName(String color) {
    final l10n = AppLocalizations.of(context)!;
    final colors = {
      'unknown': l10n.unknown,
      'yellow': l10n.yellow,
      'brown': l10n.brown,
      'green': l10n.green,
      'other': l10n.other,
    };
    return colors[color] ?? color;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'select_child':
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildSelect()));
                  loadTimeline();
                  break;
                case 'settings':
                  final appState = MyApp.of(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        onThemeChanged: () async {
                          final mode = await Storage.getThemeMode();
                          if (mounted && mode != null) {
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
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
              PopupMenuItem<String>(value: 'about', child: ListTile(leading: const Icon(Icons.info), title: Text(l10n.about))),
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

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
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
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildSelect()));
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
        Container(
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
                    onPressed: _openInBrowser,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onLongPress: _openInBrowser,
                child: Text(
                  l10n.longPressCopyLink,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
        if (_timers.isNotEmpty) ..._buildTimersList(),
        Expanded(child: _buildTimelineList()),
      ],
    );
  }

  List<Widget> _buildTimersList() {
    return _timers.map((timer) => TimerCard(
          timer: timer,
          selectedChildId: _selectedChildId,
          onTimerStopped: () => loadTimeline(),
          onTimerUsed: () => loadTimeline(),
        )).toList();
  }

  Widget _buildTimelineList() {
    final l10n = AppLocalizations.of(context)!;
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
      itemBuilder: (c, i) {
        final item = timeline[i];
        return _buildRecordCard(item);
      },
    );
  }

  Widget _buildRecordCard(dynamic item) {
    final l10n = AppLocalizations.of(context)!;
    final color = _getRecordColor(item);
    final icon = _getRecordIcon(item);
    final title = _getRecordTitle(item);
    final brief = _getRecordBrief(item);
    final timeStr = item['time'] ?? item['start'] ?? item['date'] ?? '';
    final time = _formatTime(timeStr);
    final theme = Theme.of(context);

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
              Text(brief, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
            Text(time, style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
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
                        if (childId != null) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => QuickAdd(editItem: item, childId: childId)),
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

  void _showAddMenu() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
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
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickAdd()));
                loadTimeline();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickReportOptions() {
    final l10n = AppLocalizations.of(context)!;
    final childId = _selectedChildId;
    if (childId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.quickReport, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QuickAdd(initialType: 'feeding', childId: childId)),
                      );
                      loadTimeline();
                    },
                  ),
                  _QuickReportButton(
                    icon: Icons.bedtime,
                    label: l10n.sleep,
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QuickAdd(initialType: 'sleep', childId: childId)),
                      );
                      loadTimeline();
                    },
                  ),
                  _QuickReportButton(
                    icon: Icons.baby_changing_station,
                    label: l10n.diaper,
                    color: Colors.amber,
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QuickAdd(initialType: 'change', childId: childId)),
                      );
                      loadTimeline();
                    },
                  ),
                  _QuickReportButton(
                    icon: Icons.self_improvement,
                    label: l10n.tummyTime,
                    color: Colors.green,
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QuickAdd(initialType: 'tummy_time', childId: childId)),
                      );
                      loadTimeline();
                    },
                  ),
                  _QuickReportButton(
                    icon: Icons.water_drop,
                    label: l10n.pumping,
                    color: Colors.purple,
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QuickAdd(initialType: 'pumping', childId: childId)),
                      );
                      loadTimeline();
                    },
                  ),
                  _QuickReportButton(
                    icon: Icons.edit_note,
                    label: l10n.note,
                    color: Colors.teal,
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QuickAdd(initialType: 'note', childId: childId)),
                      );
                      loadTimeline();
                    },
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
}

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

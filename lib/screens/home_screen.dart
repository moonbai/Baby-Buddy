import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/screens/child_select.dart';
import 'package:babybuddy_app/screens/quick_add.dart';
import 'package:babybuddy_app/utils/storage.dart';

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
  String? _selectedChildId;
  String? _serverUrl;
  bool _hasSelectedChild = false;

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
          _selectedChildId = childId.toString();
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
        Fluttertoast.showToast(msg: '加载时间线失败');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openInBrowser() {
    if (_serverUrl == null || _selectedChildId == null) {
      Fluttertoast.showToast(msg: '无法打开网页，请先选择宝宝');
      return;
    }
    final url = '$_serverUrl/child/$_selectedChildId/';
    Clipboard.setData(ClipboardData(text: url));
    Fluttertoast.showToast(msg: '链接已复制到剪贴板:\n$url');
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
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
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
        default:
          Fluttertoast.showToast(msg: '该类型暂不支持删除');
          return;
      }
      Fluttertoast.showToast(msg: '删除成功');
      await loadTimeline();
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: '删除失败: $e', backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadTimeline();
  }

  String _getRecordTitle(dynamic item) {
    final model = item['model']?.toString() ?? '';
    switch (model) {
      case 'sleep':
        return '睡眠';
      case 'feeding':
        return '喂奶';
      case 'change':
        return '尿布';
      case 'tummy time':
        return '俯卧时间';
      case 'pumping':
        return '吸奶';
      case 'note':
        return '笔记';
      case 'weight':
        return '体重';
      case 'height':
        return '身高';
      case 'head circumference':
        return '头围';
      case 'temperature':
        return '体温';
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
    try {
      final dt = DateTime.parse(timeStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeStr;
    }
  }

  String _getRecordBrief(dynamic item) {
    final model = item['model']?.toString() ?? '';
    switch (model) {
      case 'sleep':
        final nap = item['nap'] == true;
        final duration = item['duration'];
        return '${nap ? "小睡" : "睡觉"} ${duration != null ? "($duration)" : ""}';
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
        if (wet) result += '湿';
        if (solid) result += (result.isEmpty ? '便便' : '+便便');
        return result.isEmpty ? '未知' : result;
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
        buffer.writeln('类型: ${nap ? "小睡" : "睡觉"}');
        if (duration != null) buffer.writeln('时长: $duration');
        if (start != null) buffer.writeln('开始: ${_formatTime(start)}');
        if (end != null) buffer.writeln('结束: ${_formatTime(end)}');
        if (notes != null && notes.toString().isNotEmpty) buffer.writeln('备注: $notes');
        break;
      case 'feeding':
        final method = item['method'];
        final type = item['type'];
        final amount = item['amount'];
        final start = item['start'];
        final end = item['end'];
        final notes = item['notes'];
        if (type != null) buffer.writeln('类型: ${_getFeedingTypeName(type)}');
        if (method != null) buffer.writeln('方式: ${_getFeedingMethodName(method)}');
        if (amount != null) buffer.writeln('奶量: $amount ml');
        if (start != null) buffer.writeln('开始: ${_formatTime(start)}');
        if (end != null) buffer.writeln('结束: ${_formatTime(end)}');
        if (notes != null && notes.toString().isNotEmpty) buffer.writeln('备注: $notes');
        break;
      case 'change':
        final wet = item['wet'] == true;
        final solid = item['solid'] == true;
        final color = item['color'];
        final time = item['time'];
        final notes = item['notes'];
        buffer.writeln('类型: ${wet ? "湿" : ""}${solid ? (wet ? "+便便" : "便便") : ""}');
        if (color != null && color != 'unknown') buffer.writeln('颜色: ${_getDiaperColorName(color)}');
        if (time != null) buffer.writeln('时间: ${_formatTime(time)}');
        if (notes != null && notes.toString().isNotEmpty) buffer.writeln('备注: $notes');
        break;
      case 'pumping':
        final amount = item['amount'];
        final start = item['start'];
        final end = item['end'];
        final notes = item['notes'];
        if (amount != null) buffer.writeln('奶量: $amount ml');
        if (start != null) buffer.writeln('开始: ${_formatTime(start)}');
        if (end != null) buffer.writeln('结束: ${_formatTime(end)}');
        if (notes != null && notes.toString().isNotEmpty) buffer.writeln('备注: $notes');
        break;
      case 'note':
        final note = item['note'];
        final time = item['time'];
        if (note != null) buffer.writeln('内容: $note');
        if (time != null) buffer.writeln('时间: ${_formatTime(time)}');
        break;
      case 'tummy time':
        final duration = item['duration'];
        final start = item['start'];
        final end = item['end'];
        final milestone = item['milestone'];
        if (duration != null) buffer.writeln('时长: $duration');
        if (start != null) buffer.writeln('开始: ${_formatTime(start)}');
        if (end != null) buffer.writeln('结束: ${_formatTime(end)}');
        if (milestone != null && milestone.toString().isNotEmpty) buffer.writeln('里程碑: $milestone');
        break;
      case 'weight':
        final weight = item['weight'];
        final date = item['date'];
        if (weight != null) buffer.writeln('体重: $weight kg');
        if (date != null) buffer.writeln('日期: $date');
        break;
      case 'height':
        final height = item['height'];
        final date = item['date'];
        if (height != null) buffer.writeln('身高: $height cm');
        if (date != null) buffer.writeln('日期: $date');
        break;
      case 'head circumference':
        final circumference = item['circumference'];
        final date = item['date'];
        if (circumference != null) buffer.writeln('头围: $circumference cm');
        if (date != null) buffer.writeln('日期: $date');
        break;
      case 'temperature':
        final temp = item['temperature'];
        final time = item['time'];
        if (temp != null) buffer.writeln('体温: $temp °C');
        if (time != null) buffer.writeln('时间: ${_formatTime(time)}');
        break;
    }

    return buffer.toString().trim();
  }

  String _getFeedingTypeName(String type) {
    const types = {
      'breast milk': '母乳',
      'formula': '配方奶',
      'fortified breast milk': '强化母乳',
      'pumped milk': '泵出奶',
    };
    return types[type] ?? type;
  }

  String _getFeedingMethodName(String method) {
    const methods = {
      'left breast': '左侧乳房',
      'right breast': '右侧乳房',
      'both breasts': '双侧',
      'bottle': '奶瓶',
      'spoon': '勺子',
    };
    return methods[method] ?? method;
  }

  String _getDiaperColorName(String color) {
    const colors = {
      'unknown': '未知',
      'yellow': '黄色',
      'brown': '棕色',
      'green': '绿色',
      'other': '其他',
    };
    return colors[color] ?? color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baby Buddy'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildSelect()));
              loadTimeline();
            },
            icon: const Icon(Icons.person),
            tooltip: '选择宝宝',
          ),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: _hasSelectedChild
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickAdd()));
                loadTimeline();
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
    if (!_hasSelectedChild) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              '请先选择宝宝',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              '点击右上角图标选择宝宝',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildSelect()));
                loadTimeline();
              },
              icon: const Icon(Icons.person),
              label: const Text('选择宝宝'),
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
              '加载失败',
              style: TextStyle(fontSize: 18, color: Colors.red[300]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: loadTimeline,
              child: const Text('重新加载'),
            ),
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
                      _selectedChildName![0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '当前宝宝',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _selectedChildName!,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    tooltip: '点击复制网页链接',
                    onPressed: _openInBrowser,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onLongPress: _openInBrowser,
                child: Text(
                  '长按可复制网页链接',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildTimelineList()),
      ],
    );
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
              '暂无记录',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角 + 添加记录',
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
    final color = _getRecordColor(item);
    final icon = _getRecordIcon(item);
    final title = _getRecordTitle(item);
    final brief = _getRecordBrief(item);
    final timeStr = item['time'] ?? item['start'] ?? item['date'] ?? '';
    final time = _formatTime(timeStr);
    final model = item['model']?.toString() ?? '';

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
              Text(brief, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRecordDetail(item),
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (model == 'sleep' || model == 'feeding' || model == 'change' || model == 'note')
                      TextButton.icon(
                        onPressed: () => deleteRecord(item),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('删除'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
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
}

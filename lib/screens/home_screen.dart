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

  Future<void> loadTimeline() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final childId = await Storage.getChildId();
      final serverUrl = await Storage.getServerUrl();
      
      if (childId != null) {
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
        return Colors.yellow;
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

  String _getRecordSubtitle(dynamic item) {
    final model = item['model']?.toString() ?? '';
    final time = item['time'] ?? item['start'] ?? item['date'] ?? '';
    
    switch (model) {
      case 'sleep':
        final duration = item['duration'];
        if (duration != null) {
          return '时长: $duration';
        }
        return time;
      case 'feeding':
        final method = item['method'];
        final type = item['type'];
        if (method != null && type != null) {
          return '$type - $method';
        }
        return time;
      case 'change':
        final wet = item['wet'] == true;
        final solid = item['solid'] == true;
        String result = '';
        if (wet) result += '湿';
        if (solid) result += (result.isEmpty ? '便便' : ', 便便');
        return result.isEmpty ? time : '$result $time';
      case 'pumping':
        final amount = item['amount'];
        if (amount != null) {
          return '量: ${amount}ml';
        }
        return time;
      case 'weight':
        final weight = item['weight'];
        if (weight != null) {
          return '体重: ${weight}kg';
        }
        return time;
      case 'height':
        final height = item['height'];
        if (height != null) {
          return '身高: ${height}cm';
        }
        return time;
      case 'temperature':
        final temp = item['temperature'];
        if (temp != null) {
          return '体温: ${temp}°C';
        }
        return time;
      default:
        return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baby Buddy'),
        actions: [
          IconButton(onPressed: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ChildSelect())), icon: const Icon(Icons.person)),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const QuickAdd())),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: loadTimeline,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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

    if (_selectedChildName != null) {
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _selectedChildName!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      tooltip: '长按复制链接到剪贴板',
                      onPressed: _openInBrowser,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onLongPress: _openInBrowser,
                  child: Text(
                    '长按可复制网页链接',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildTimelineList(),
          ),
        ],
      );
    }

    return _buildTimelineList();
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
            if (_selectedChildName == null) ...[
              const SizedBox(height: 8),
              Text(
                '请先选择宝宝',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: timeline.length,
      itemBuilder: (c, i) {
        final item = timeline[i];
        final color = _getRecordColor(item);
        final icon = _getRecordIcon(item);
        final title = _getRecordTitle(item);
        final subtitle = _getRecordSubtitle(item);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            title: Text(title),
            subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
          ),
        );
      },
    );
  }
}

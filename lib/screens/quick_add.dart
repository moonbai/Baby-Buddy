import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/utils/storage.dart';

class QuickAdd extends StatefulWidget {
  final Map<String, dynamic>? editItem;
  final int? childId;

  const QuickAdd({super.key, this.editItem, this.childId});

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  int? childId;
  bool _isLoading = false;
  String? _editModel;
  Map<String, dynamic>? _editItem;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    if (widget.editItem != null) {
      setState(() {
        _editItem = widget.editItem;
        _editModel = widget.editItem!['model'];
        childId = widget.childId;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEditOptions();
      });
    } else {
      final storedChildId = await Storage.getChildId();
      setState(() {
        childId = storedChildId;
      });
    }
  }

  void _showEditOptions() {
    if (_editModel == null || _editItem == null) return;

    switch (_editModel) {
      case 'feeding':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => FeedingOptions(
            childId: childId!,
            editItem: _editItem,
            onSaved: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        );
        break;
      case 'sleep':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => SleepOptions(
            childId: childId!,
            editItem: _editItem,
            onSaved: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        );
        break;
      case 'change':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => DiaperOptions(
            childId: childId!,
            editItem: _editItem,
            onSaved: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        );
        break;
      case 'tummy time':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => TummyTimeOptions(
            childId: childId!,
            editItem: _editItem,
            onSaved: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        );
        break;
      case 'pumping':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => PumpingOptions(
            childId: childId!,
            editItem: _editItem,
            onSaved: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        );
        break;
      case 'note':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => NoteOptions(
            childId: childId!,
            editItem: _editItem,
            onSaved: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        );
        break;
      case 'weight':
      case 'height':
      case 'head circumference':
      case 'temperature':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => MeasurementOptions(
            childId: childId!,
            editItem: _editItem,
            onSaved: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        );
        break;
      default:
        Fluttertoast.showToast(msg: '该类型暂不支持编辑');
    }
  }

  String fmt(DateTime t) => DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(t);

  void _showFeedingOptions() {
    if (childId == null) {
      Fluttertoast.showToast(msg: '请先选择宝宝');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FeedingOptions(
        childId: childId!,
        onSaved: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSleepOptions() {
    if (childId == null) {
      Fluttertoast.showToast(msg: '请先选择宝宝');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SleepOptions(
        childId: childId!,
        onSaved: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDiaperOptions() {
    if (childId == null) {
      Fluttertoast.showToast(msg: '请先选择宝宝');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DiaperOptions(
        childId: childId!,
        onSaved: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showTummyTimeOptions() {
    if (childId == null) {
      Fluttertoast.showToast(msg: '请先选择宝宝');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TummyTimeOptions(
        childId: childId!,
        onSaved: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showPumpingOptions() {
    if (childId == null) {
      Fluttertoast.showToast(msg: '请先选择宝宝');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PumpingOptions(
        childId: childId!,
        onSaved: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showNoteOptions() {
    if (childId == null) {
      Fluttertoast.showToast(msg: '请先选择宝宝');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NoteOptions(
        childId: childId!,
        onSaved: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showMeasurementOptions() {
    if (childId == null) {
      Fluttertoast.showToast(msg: '请先选择宝宝');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MeasurementOptions(
        childId: childId!,
        onSaved: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('快速记录')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildQuickAction(
                  icon: Icons.restaurant,
                  label: '喂奶',
                  color: Colors.orange,
                  onTap: _showFeedingOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.bedtime,
                  label: '睡眠',
                  color: Colors.blue,
                  onTap: _showSleepOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.baby_changing_station,
                  label: '尿布',
                  color: Colors.yellow,
                  onTap: _showDiaperOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.self_improvement,
                  label: '俯卧时间',
                  color: Colors.green,
                  onTap: _showTummyTimeOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.water_drop,
                  label: '吸奶',
                  color: Colors.purple,
                  onTap: _showPumpingOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.note,
                  label: '笔记',
                  color: Colors.teal,
                  onTap: _showNoteOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.monitor_weight,
                  label: '身体测量',
                  color: Colors.deepPurple,
                  onTap: _showMeasurementOptions,
                ),
              ],
            ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedingOptions extends StatefulWidget {
  final int childId;
  final VoidCallback onSaved;
  final Map<String, dynamic>? editItem;
  const FeedingOptions({
    super.key,
    required this.childId,
    required this.onSaved,
    this.editItem,
  });

  @override
  State<FeedingOptions> createState() => _FeedingOptionsState();
}

class _FeedingOptionsState extends State<FeedingOptions> {
  String _selectedType = 'breast milk';
  String _selectedMethod = 'left breast';
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(minutes: 20));
  bool _isLoading = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      final item = widget.editItem!;
      _selectedType = item['type'] ?? _selectedType;
      _selectedMethod = item['method'] ?? _selectedMethod;
      if (item['start'] != null) {
        _startTime = DateTime.parse(item['start']);
      }
      if (item['end'] != null) {
        _endTime = DateTime.parse(item['end']);
      }
      if (item['amount'] != null) {
        _amountController.text = item['amount'].toString();
      }
      if (item['notes'] != null) {
        _notesController.text = item['notes'].toString();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  final Map<String, String> _feedingTypesMap = const {
    'breast milk': '母乳',
    'formula': '配方奶',
    'fortified breast milk': '强化母乳',
    'pumped milk': '泵出奶',
  };

  final Map<String, String> _feedingMethodsMap = const {
    'left breast': '左侧乳房',
    'right breast': '右侧乳房',
    'both breasts': '双侧',
    'bottle': '奶瓶',
    'spoon': '勺子',
  };

  final List<String> _feedingTypes = const ['breast milk', 'formula', 'fortified breast milk', 'pumped milk'];
  final List<String> _feedingMethods = const ['left breast', 'right breast', 'both breasts', 'bottle', 'spoon'];

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      double? amount;
      if (_amountController.text.isNotEmpty) {
        amount = double.tryParse(_amountController.text);
      }
      
      if (widget.editItem != null) {
        final data = <String, dynamic>{
          'child': widget.childId,
          'start': DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
          'end': DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
          'type': _selectedType,
          'method': _selectedMethod,
        };
        if (amount != null) {
          data['amount'] = amount;
          data['amount_unit'] = 'ml';
        }
        if (_notesController.text.isNotEmpty) {
          data['notes'] = _notesController.text;
        }
        await ApiService.updateFeeding(widget.editItem!['id'], data);
        Fluttertoast.showToast(msg: '喂奶记录已更新');
      } else {
        await ApiService.addFeeding(
          widget.childId,
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
          _selectedType,
          _selectedMethod,
          amount: amount,
          amountUnit: 'ml',
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        Fluttertoast.showToast(msg: '喂奶记录已添加');
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? '更新失败' : '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg：网络错误，请检查网络连接';
        }
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '编辑喂奶记录' : '记录喂奶',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection('喂养类型'),
            const SizedBox(height: 8),
            _buildOptions(_feedingTypes, _selectedType, (v) => setState(() => _selectedType = v)),
            const SizedBox(height: 16),
            _buildSection('喂养方式'),
            const SizedBox(height: 8),
            _buildOptions(_feedingMethods, _selectedMethod, (v) => setState(() => _selectedMethod = v)),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '奶量 (ml)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? '更新记录' : '保存记录'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildOptions(List<String> options, String selected, ValueChanged<String> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        String displayText = option;
        if (_feedingTypesMap.containsKey(option)) {
          displayText = _feedingTypesMap[option]!;
        } else if (_feedingMethodsMap.containsKey(option)) {
          displayText = _feedingMethodsMap[option]!;
        }
        return ChoiceChip(
          label: Text(displayText),
          selected: isSelected,
          onSelected: (_) => onChanged(option),
        );
      }).toList(),
    );
  }
}

class SleepOptions extends StatefulWidget {
  final int childId;
  final VoidCallback onSaved;
  final Map<String, dynamic>? editItem;
  const SleepOptions({
    super.key,
    required this.childId,
    required this.onSaved,
    this.editItem,
  });

  @override
  State<SleepOptions> createState() => _SleepOptionsState();
}

class _SleepOptionsState extends State<SleepOptions> {
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  bool _isNap = false;
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      final item = widget.editItem!;
      _isNap = item['nap'] ?? false;
      if (item['start'] != null) {
        _startTime = DateTime.parse(item['start']);
      }
      if (item['end'] != null) {
        _endTime = DateTime.parse(item['end']);
      }
      if (item['notes'] != null) {
        _notesController.text = item['notes'].toString();
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      if (widget.editItem != null) {
        final data = <String, dynamic>{
          'child': widget.childId,
          'start': DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
          'end': DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
          'nap': _isNap,
        };
        if (_notesController.text.isNotEmpty) {
          data['notes'] = _notesController.text;
        }
        await ApiService.updateSleep(widget.editItem!['id'], data);
        Fluttertoast.showToast(msg: '睡眠记录已更新');
      } else {
        await ApiService.addSleep(
          widget.childId,
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
          nap: _isNap,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        Fluttertoast.showToast(msg: '睡眠记录已添加');
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? '更新失败' : '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg：网络错误，请检查网络连接';
        }
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '编辑睡眠记录' : '记录睡眠',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('小睡'),
                Switch(
                  value: _isNap,
                  onChanged: (v) => setState(() => _isNap = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? '更新记录' : '保存记录'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiaperOptions extends StatefulWidget {
  final int childId;
  final VoidCallback onSaved;
  final Map<String, dynamic>? editItem;
  const DiaperOptions({
    super.key,
    required this.childId,
    required this.onSaved,
    this.editItem,
  });

  @override
  State<DiaperOptions> createState() => _DiaperOptionsState();
}

class _DiaperOptionsState extends State<DiaperOptions> {
  bool _wet = true;
  bool _solid = false;
  final _colors = const ['unknown', 'yellow', 'brown', 'green', 'other'];
  String _selectedColor = 'unknown';
  bool _isLoading = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      final item = widget.editItem!;
      _wet = item['wet'] ?? true;
      _solid = item['solid'] ?? false;
      _selectedColor = item['color'] ?? 'unknown';
      if (item['notes'] != null) {
        _notesController.text = item['notes'].toString();
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  final Map<String, String> _colorMap = const {
    'unknown': '未知',
    'yellow': '黄色',
    'brown': '棕色',
    'green': '绿色',
    'other': '其他',
  };

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      if (widget.editItem != null) {
        final data = <String, dynamic>{
          'child': widget.childId,
          'time': widget.editItem!['time'] ?? DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now()),
          'wet': _wet,
          'solid': _solid,
          'color': _selectedColor,
        };
        if (_notesController.text.isNotEmpty) {
          data['notes'] = _notesController.text;
        }
        await ApiService.updateDiaper(widget.editItem!['id'], data);
        Fluttertoast.showToast(msg: '尿布记录已更新');
      } else {
        await ApiService.addDiaper(
          widget.childId,
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now()),
          _wet,
          _solid,
          _selectedColor,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        Fluttertoast.showToast(msg: '尿布记录已添加');
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? '更新失败' : '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg：网络错误，请检查网络连接';
        }
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '编辑尿布记录' : '记录尿布',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection('类型'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCheckbox('湿', _wet, (v) => setState(() => _wet = v ?? true)),
                ),
                Expanded(
                  child: _buildCheckbox('干/便便', _solid, (v) => setState(() => _solid = v ?? false)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection('颜色'),
            const SizedBox(height: 8),
            _buildOptions(_colors, _selectedColor, (v) => setState(() => _selectedColor = v)),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? '更新记录' : '保存记录'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }

  Widget _buildOptions(List<String> options, String selected, ValueChanged<String> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        String displayText = _colorMap[option] ?? option;
        return ChoiceChip(
          label: Text(displayText),
          selected: isSelected,
          onSelected: (_) => onChanged(option),
        );
      }).toList(),
    );
  }
}

class TummyTimeOptions extends StatefulWidget {
  final int childId;
  final VoidCallback onSaved;
  final Map<String, dynamic>? editItem;
  const TummyTimeOptions({
    super.key,
    required this.childId,
    required this.onSaved,
    this.editItem,
  });

  @override
  State<TummyTimeOptions> createState() => _TummyTimeOptionsState();
}

class _TummyTimeOptionsState extends State<TummyTimeOptions> {
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(minutes: 10));
  final TextEditingController _milestoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      final item = widget.editItem!;
      if (item['start'] != null) {
        _startTime = DateTime.parse(item['start']);
      }
      if (item['end'] != null) {
        _endTime = DateTime.parse(item['end']);
      }
      if (item['milestone'] != null) {
        _milestoneController.text = item['milestone'].toString();
      }
      if (item['notes'] != null) {
        _notesController.text = item['notes'].toString();
      }
    }
  }

  @override
  void dispose() {
    _milestoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      if (widget.editItem != null) {
        final data = <String, dynamic>{
          'child': widget.childId,
          'start': DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
          'end': DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
        };
        if (_milestoneController.text.isNotEmpty) {
          data['milestone'] = _milestoneController.text;
        }
        if (_notesController.text.isNotEmpty) {
          data['notes'] = _notesController.text;
        }
        await ApiService.updateTummyTime(widget.editItem!['id'], data);
        Fluttertoast.showToast(msg: '俯卧时间已更新');
      } else {
        await ApiService.addTummyTime(
          widget.childId,
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
          milestone: _milestoneController.text.isNotEmpty ? _milestoneController.text : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        Fluttertoast.showToast(msg: '俯卧时间已添加');
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? '更新失败' : '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg：网络错误，请检查网络连接';
        }
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '编辑俯卧时间' : '记录俯卧时间',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _milestoneController,
              decoration: const InputDecoration(
                labelText: '里程碑 (可选)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? '更新记录' : '保存记录'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PumpingOptions extends StatefulWidget {
  final int childId;
  final VoidCallback onSaved;
  final Map<String, dynamic>? editItem;
  const PumpingOptions({
    super.key,
    required this.childId,
    required this.onSaved,
    this.editItem,
  });

  @override
  State<PumpingOptions> createState() => _PumpingOptionsState();
}

class _PumpingOptionsState extends State<PumpingOptions> {
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(minutes: 15));
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      final item = widget.editItem!;
      if (item['start'] != null) {
        _startTime = DateTime.parse(item['start']);
      }
      if (item['end'] != null) {
        _endTime = DateTime.parse(item['end']);
      }
      if (item['amount'] != null) {
        _amountController.text = item['amount'].toString();
      }
      if (item['notes'] != null) {
        _notesController.text = item['notes'].toString();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      double? amount;
      if (_amountController.text.isNotEmpty) {
        amount = double.tryParse(_amountController.text);
      }
      
      if (widget.editItem != null) {
        final data = <String, dynamic>{
          'child': widget.childId,
          'start': DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
          'end': DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
        };
        if (amount != null) {
          data['amount'] = amount;
          data['amount_unit'] = 'ml';
        }
        if (_notesController.text.isNotEmpty) {
          data['notes'] = _notesController.text;
        }
        await ApiService.updatePumping(widget.editItem!['id'], data);
        Fluttertoast.showToast(msg: '吸奶记录已更新');
      } else {
        await ApiService.addPumping(
          widget.childId,
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
          amount: amount,
          amountUnit: 'ml',
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        Fluttertoast.showToast(msg: '吸奶记录已添加');
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? '更新失败' : '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg：网络错误，请检查网络连接';
        }
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '编辑吸奶记录' : '记录吸奶',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '奶量 (ml)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? '更新记录' : '保存记录'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteOptions extends StatefulWidget {
  final int childId;
  final VoidCallback onSaved;
  final Map<String, dynamic>? editItem;
  const NoteOptions({
    super.key,
    required this.childId,
    required this.onSaved,
    this.editItem,
  });

  @override
  State<NoteOptions> createState() => _NoteOptionsState();
}

class _NoteOptionsState extends State<NoteOptions> {
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      final item = widget.editItem!;
      if (item['note'] != null) {
        _noteController.text = item['note'].toString();
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_noteController.text.isEmpty) {
      Fluttertoast.showToast(msg: '请输入笔记内容');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      if (widget.editItem != null) {
        final data = <String, dynamic>{
          'child': widget.childId,
          'note': _noteController.text,
        };
        await ApiService.updateNote(widget.editItem!['id'], data);
        Fluttertoast.showToast(msg: '笔记已更新');
      } else {
        await ApiService.addNote(
          widget.childId,
          _noteController.text,
        );
        Fluttertoast.showToast(msg: '笔记已添加');
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? '更新失败' : '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg：网络错误，请检查网络连接';
        }
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '编辑笔记' : '添加笔记',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '笔记内容',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? '更新笔记' : '保存笔记'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeasurementOptions extends StatefulWidget {
  final int childId;
  final VoidCallback onSaved;
  final Map<String, dynamic>? editItem;
  const MeasurementOptions({
    super.key,
    required this.childId,
    required this.onSaved,
    this.editItem,
  });

  @override
  State<MeasurementOptions> createState() => _MeasurementOptionsState();
}

class _MeasurementOptionsState extends State<MeasurementOptions> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _headCircController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  String? _editingModel;

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      final item = widget.editItem!;
      _editingModel = item['model'];
      if (_editingModel == 'weight' && item['weight'] != null) {
        _weightController.text = item['weight'].toString();
      } else if (_editingModel == 'height' && item['height'] != null) {
        _heightController.text = item['height'].toString();
      } else if (_editingModel == 'head circumference' && item['circumference'] != null) {
        _headCircController.text = item['circumference'].toString();
      } else if (_editingModel == 'temperature' && item['temperature'] != null) {
        _tempController.text = item['temperature'].toString();
      }
      if (item['notes'] != null) {
        _notesController.text = item['notes'].toString();
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _headCircController.dispose();
    _tempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_editingModel == null) {
      if (_weightController.text.isEmpty && 
          _heightController.text.isEmpty && 
          _headCircController.text.isEmpty &&
          _tempController.text.isEmpty) {
        Fluttertoast.showToast(msg: '请至少输入一项测量值');
        return;
      }
    } else {
      bool hasInput = false;
      if (_editingModel == 'weight' && _weightController.text.isNotEmpty) hasInput = true;
      if (_editingModel == 'height' && _heightController.text.isNotEmpty) hasInput = true;
      if (_editingModel == 'head circumference' && _headCircController.text.isNotEmpty) hasInput = true;
      if (_editingModel == 'temperature' && _tempController.text.isNotEmpty) hasInput = true;
      if (!hasInput) {
        Fluttertoast.showToast(msg: '请输入测量值');
        return;
      }
    }
    
    setState(() => _isLoading = true);
    try {
      if (widget.editItem != null && _editingModel != null) {
        final date = widget.editItem!['date'] ?? DateFormat("yyyy-MM-dd").format(DateTime.now());
        final time = widget.editItem!['time'];
        if (_editingModel == 'weight' && _weightController.text.isNotEmpty) {
          final data = <String, dynamic>{
            'child': widget.childId,
            'date': date,
            'weight': double.parse(_weightController.text),
            'weight_unit': 'kg',
          };
          if (_notesController.text.isNotEmpty) {
            data['notes'] = _notesController.text;
          }
          await ApiService.updateWeight(widget.editItem!['id'], data);
        } else if (_editingModel == 'height' && _heightController.text.isNotEmpty) {
          final data = <String, dynamic>{
            'child': widget.childId,
            'date': date,
            'height': double.parse(_heightController.text),
            'height_unit': 'cm',
          };
          if (_notesController.text.isNotEmpty) {
            data['notes'] = _notesController.text;
          }
          await ApiService.updateHeight(widget.editItem!['id'], data);
        } else if (_editingModel == 'head circumference' && _headCircController.text.isNotEmpty) {
          final data = <String, dynamic>{
            'child': widget.childId,
            'date': date,
            'circumference': double.parse(_headCircController.text),
            'circumference_unit': 'cm',
          };
          if (_notesController.text.isNotEmpty) {
            data['notes'] = _notesController.text;
          }
          await ApiService.updateHeadCircumference(widget.editItem!['id'], data);
        } else if (_editingModel == 'temperature' && _tempController.text.isNotEmpty) {
          final data = <String, dynamic>{
            'child': widget.childId,
            'time': time ?? DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now()),
            'temperature': double.parse(_tempController.text),
            'temperature_unit': 'C',
          };
          if (_notesController.text.isNotEmpty) {
            data['notes'] = _notesController.text;
          }
          await ApiService.updateTemperature(widget.editItem!['id'], data);
        }
        Fluttertoast.showToast(msg: '测量记录已更新');
      } else {
        final date = DateFormat("yyyy-MM-dd").format(DateTime.now());
        final time = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now());
        
        if (_weightController.text.isNotEmpty) {
          await ApiService.addWeight(
            widget.childId,
            date,
            double.parse(_weightController.text),
            weightUnit: 'kg',
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
        }
        
        if (_heightController.text.isNotEmpty) {
          await ApiService.addHeight(
            widget.childId,
            date,
            double.parse(_heightController.text),
            heightUnit: 'cm',
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
        }
        
        if (_headCircController.text.isNotEmpty) {
          await ApiService.addHeadCircumference(
            widget.childId,
            date,
            double.parse(_headCircController.text),
            circumferenceUnit: 'cm',
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
        }

        if (_tempController.text.isNotEmpty) {
          await ApiService.addTemperature(
            widget.childId,
            time,
            double.parse(_tempController.text),
            temperatureUnit: 'C',
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
        }
        
        Fluttertoast.showToast(msg: '测量记录已添加');
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? '更新失败' : '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg：网络错误，请检查网络连接';
        }
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.editItem != null ? '编辑身体测量' : '记录身体测量';
    if (_editingModel == 'weight') title = '编辑体重记录';
    if (_editingModel == 'height') title = '编辑身高记录';
    if (_editingModel == 'head circumference') title = '编辑头围记录';
    if (_editingModel == 'temperature') title = '编辑体温记录';
    
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (_editingModel == null || _editingModel == 'weight')
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '体重 (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_editingModel == null || _editingModel == 'weight')
              const SizedBox(height: 16),
            if (_editingModel == null || _editingModel == 'height')
              TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '身高 (cm)',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_editingModel == null || _editingModel == 'height')
              const SizedBox(height: 16),
            if (_editingModel == null || _editingModel == 'head circumference')
              TextField(
                controller: _headCircController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '头围 (cm)',
                  border: OutlineInputBorder(),
                ),
              ),
            if ((_editingModel == null || _editingModel == 'head circumference') && 
                (_editingModel == null || _editingModel == 'temperature'))
              const SizedBox(height: 16),
            if (_editingModel == null || _editingModel == 'temperature')
              TextField(
                controller: _tempController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '体温 (°C)',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? '更新记录' : '保存记录'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

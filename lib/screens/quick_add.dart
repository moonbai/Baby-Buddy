import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/utils/storage.dart';

class QuickAdd extends StatefulWidget {
  const QuickAdd({super.key});

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  int? childId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Storage.getChildId().then((v) => setState(() => childId = v));
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
  const FeedingOptions({
    super.key,
    required this.childId,
    required this.onSaved,
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

  final Map<String, String> _feedingTypesMap = {
    'breast milk': '母乳',
    'formula': '配方奶',
    'fortified breast milk': '强化母乳',
    'pumped milk': '泵出奶',
  };

  final Map<String, String> _feedingMethodsMap = {
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
      
      await ApiService.addFeeding(
        widget.childId,
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
        _selectedType,
        _selectedMethod,
        amount: amount,
        amountUnit: 'ml',
      );
      Fluttertoast.showToast(msg: '喂奶记录已添加');
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '添加失败：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '添加失败：网络错误，请检查网络连接';
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
            const Text(
              '记录喂奶',
              style: TextStyle(
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : const Text('保存记录'),
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
  const SleepOptions({
    super.key,
    required this.childId,
    required this.onSaved,
  });

  @override
  State<SleepOptions> createState() => _SleepOptionsState();
}

class _SleepOptionsState extends State<SleepOptions> {
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  bool _isNap = false;
  bool _isLoading = false;

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.addSleep(
        widget.childId,
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
        nap: _isNap,
      );
      Fluttertoast.showToast(msg: '睡眠记录已添加');
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '添加失败：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '添加失败：网络错误，请检查网络连接';
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
            const Text(
              '记录睡眠',
              style: TextStyle(
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : const Text('保存记录'),
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
  const DiaperOptions({
    super.key,
    required this.childId,
    required this.onSaved,
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

  final Map<String, String> _colorMap = {
    'unknown': '未知',
    'yellow': '黄色',
    'brown': '棕色',
    'green': '绿色',
    'other': '其他',
  };

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.addDiaper(
        widget.childId,
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now()),
        _wet,
        _solid,
        _selectedColor,
      );
      Fluttertoast.showToast(msg: '尿布记录已添加');
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '添加失败：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '添加失败：网络错误，请检查网络连接';
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
            const Text(
              '记录尿布',
              style: TextStyle(
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : const Text('保存记录'),
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
  const TummyTimeOptions({
    super.key,
    required this.childId,
    required this.onSaved,
  });

  @override
  State<TummyTimeOptions> createState() => _TummyTimeOptionsState();
}

class _TummyTimeOptionsState extends State<TummyTimeOptions> {
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(minutes: 10));
  final TextEditingController _milestoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.addTummyTime(
        widget.childId,
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
        milestone: _milestoneController.text.isNotEmpty ? _milestoneController.text : null,
      );
      Fluttertoast.showToast(msg: '俯卧时间已添加');
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '添加失败：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '添加失败：网络错误，请检查网络连接';
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
            const Text(
              '记录俯卧时间',
              style: TextStyle(
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : const Text('保存记录'),
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
  const PumpingOptions({
    super.key,
    required this.childId,
    required this.onSaved,
  });

  @override
  State<PumpingOptions> createState() => _PumpingOptionsState();
}

class _PumpingOptionsState extends State<PumpingOptions> {
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(minutes: 15));
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      double? amount;
      if (_amountController.text.isNotEmpty) {
        amount = double.tryParse(_amountController.text);
      }
      
      await ApiService.addPumping(
        widget.childId,
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
        amount: amount,
        amountUnit: 'ml',
      );
      Fluttertoast.showToast(msg: '吸奶记录已添加');
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '添加失败：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '添加失败：网络错误，请检查网络连接';
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
            const Text(
              '记录吸奶',
              style: TextStyle(
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : const Text('保存记录'),
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
  const NoteOptions({
    super.key,
    required this.childId,
    required this.onSaved,
  });

  @override
  State<NoteOptions> createState() => _NoteOptionsState();
}

class _NoteOptionsState extends State<NoteOptions> {
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  Future<void> _save() async {
    if (_noteController.text.isEmpty) {
      Fluttertoast.showToast(msg: '请输入笔记内容');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await ApiService.addNote(
        widget.childId,
        _noteController.text,
      );
      Fluttertoast.showToast(msg: '笔记已添加');
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '添加失败：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '添加失败：网络错误，请检查网络连接';
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
            const Text(
              '添加笔记',
              style: TextStyle(
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
                child: _isLoading ? const CircularProgressIndicator() : const Text('保存笔记'),
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
  const MeasurementOptions({
    super.key,
    required this.childId,
    required this.onSaved,
  });

  @override
  State<MeasurementOptions> createState() => _MeasurementOptionsState();
}

class _MeasurementOptionsState extends State<MeasurementOptions> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _headCircController = TextEditingController();
  bool _isLoading = false;

  Future<void> _save() async {
    if (_weightController.text.isEmpty && 
        _heightController.text.isEmpty && 
        _headCircController.text.isEmpty) {
      Fluttertoast.showToast(msg: '请至少输入一项测量值');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final date = DateFormat("yyyy-MM-dd").format(DateTime.now());
      
      if (_weightController.text.isNotEmpty) {
        await ApiService.addWeight(
          widget.childId,
          date,
          double.parse(_weightController.text),
          weightUnit: 'kg',
        );
      }
      
      if (_heightController.text.isNotEmpty) {
        await ApiService.addHeight(
          widget.childId,
          date,
          double.parse(_heightController.text),
          heightUnit: 'cm',
        );
      }
      
      if (_headCircController.text.isNotEmpty) {
        await ApiService.addHeadCircumference(
          widget.childId,
          date,
          double.parse(_headCircController.text),
          circumferenceUnit: 'cm',
        );
      }
      
      Fluttertoast.showToast(msg: '测量记录已添加');
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = '添加失败';
        if (e.toString().contains('403')) {
          errorMsg = '添加失败：没有权限，请重新登录';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '添加失败：网络错误，请检查网络连接';
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
            const Text(
              '记录身体测量',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '体重 (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '身高 (cm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _headCircController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '头围 (cm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : const Text('保存记录'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

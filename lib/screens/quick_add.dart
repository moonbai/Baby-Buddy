import 'package:flutter/material.dart';
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
      builder: (context) => DiaperOptions(
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
      body: Center(
        child: _isLoading
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickAction(
                  icon: Icons.restaurant,
                  label: '喂奶',
                  color: Colors.orange,
                  onTap: _showFeedingOptions,
                ),
                const SizedBox(height: 16),
                _buildQuickAction(
                  icon: Icons.bedtime,
                  label: '睡眠',
                  color: Colors.blue,
                  onTap: _showSleepOptions,
                ),
                const SizedBox(height: 16),
                _buildQuickAction(
                  icon: Icons.baby_changing_station,
                  label: '尿布',
                  color: Colors.yellow,
                  onTap: _showDiaperOptions,
                ),
              ],
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
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

  final _feedingTypes = const ['breast milk', 'formula', 'fortified breast milk', 'pumped milk'];
  final _feedingMethods = const ['left breast', 'right breast', 'both breasts', 'bottle', 'spoon'];

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.addFeeding(
        widget.childId,
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
        _selectedType,
        _selectedMethod,
      );
      Fluttertoast.showToast(msg: '喂奶记录已添加');
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: '添加失败: $e',
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onChanged(option),
          backgroundColor: Colors.grey[100],
          selectedColor: Colors.blue[100],
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
  bool _isLoading = false;

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.addSleep(
        widget.childId,
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_startTime),
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_endTime),
      );
      Fluttertoast.showToast(msg: '睡眠记录已添加');
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: '添加失败: $e',
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
          const Text(
            '时间会自动设置为现在和2小时后（默认），可以根据需要修改',
            style: TextStyle(color: Colors.grey),
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
        Fluttertoast.showToast(
          msg: '添加失败: $e',
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onChanged(option),
          backgroundColor: Colors.grey[100],
          selectedColor: Colors.blue[100],
        );
      }).toList(),
    );
  }
}

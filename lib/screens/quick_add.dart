import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:babybuddy_app/utils/date_time_utils.dart';
import 'package:babybuddy_app/generated/app_localizations.dart';

class QuickAdd extends StatefulWidget {
  final Map<String, dynamic>? editItem;
  final int? childId;
  final String? initialType;

  const QuickAdd({super.key, this.editItem, this.childId, this.initialType});

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
    } else if (widget.initialType != null) {
      final storedChildId = widget.childId ?? await Storage.getChildId();
      setState(() {
        childId = storedChildId;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInitialTypeOptions();
      });
    } else {
      final storedChildId = await Storage.getChildId();
      setState(() {
        childId = storedChildId;
      });
    }
  }

  void _showInitialTypeOptions() {
    switch (widget.initialType) {
      case 'feeding':
        _showFeedingOptions();
        break;
      case 'sleep':
        _showSleepOptions();
        break;
      case 'change':
        _showDiaperOptions();
        break;
      case 'tummy_time':
        _showTummyTimeOptions();
        break;
      case 'pumping':
        _showPumpingOptions();
        break;
      case 'note':
        _showNoteOptions();
        break;
    }
  }

  void _showEditOptions() {
    if (_editModel == null || _editItem == null) return;

    final l10n = AppLocalizations.of(context)!;
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
        Fluttertoast.showToast(msg: l10n.typeNotSupported);
    }
  }

  void _showFeedingOptions() {
    final l10n = AppLocalizations.of(context)!;
    if (childId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
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
    final l10n = AppLocalizations.of(context)!;
    if (childId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
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
    final l10n = AppLocalizations.of(context)!;
    if (childId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
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
    final l10n = AppLocalizations.of(context)!;
    if (childId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
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
    final l10n = AppLocalizations.of(context)!;
    if (childId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
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
    final l10n = AppLocalizations.of(context)!;
    if (childId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
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
    final l10n = AppLocalizations.of(context)!;
    if (childId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quickAdd)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildQuickAction(
                  icon: Icons.restaurant,
                  label: l10n.feeding,
                  color: Colors.orange,
                  onTap: _showFeedingOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.bedtime,
                  label: l10n.sleep,
                  color: Colors.blue,
                  onTap: _showSleepOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.baby_changing_station,
                  label: l10n.diaper,
                  color: Colors.yellow,
                  onTap: _showDiaperOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.self_improvement,
                  label: l10n.tummyTime,
                  color: Colors.green,
                  onTap: _showTummyTimeOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.water_drop,
                  label: l10n.pumping,
                  color: Colors.purple,
                  onTap: _showPumpingOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.note,
                  label: l10n.note,
                  color: Colors.teal,
                  onTap: _showNoteOptions,
                ),
                const SizedBox(height: 12),
                _buildQuickAction(
                  icon: Icons.monitor_weight,
                  label: l10n.weight + ' / ' + l10n.height,
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
  final Map<String, dynamic>? timer;
  const FeedingOptions({
    super.key,
    required this.childId,
    required this.onSaved,
    this.editItem,
    this.timer,
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
    if (widget.timer != null) {
      final timer = widget.timer!;
      if (timer['start'] != null) {
        _startTime = DateTimeUtils.parseServerTime(timer['start']);
        _endTime = DateTime.now();
      }
    } else if (widget.editItem != null) {
      final item = widget.editItem!;
      _selectedType = item['type'] ?? _selectedType;
      _selectedMethod = item['method'] ?? _selectedMethod;
      if (item['start'] != null) {
        _startTime = DateTimeUtils.parseServerTime(item['start']);
      }
      if (item['end'] != null) {
        _endTime = DateTimeUtils.parseServerTime(item['end']);
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

  final List<String> _feedingTypes = const ['breast milk', 'formula', 'fortified breast milk', 'pumped milk'];
  final List<String> _feedingMethods = const ['left breast', 'right breast', 'both breasts', 'bottle', 'spoon'];

  String _getTypeName(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'breast milk':
        return l10n.breastMilk;
      case 'formula':
        return l10n.formula;
      case 'fortified breast milk':
        return l10n.fortifiedBreastMilk;
      case 'pumped milk':
        return l10n.pumpedMilk;
      default:
        return type;
    }
  }

  String _getMethodName(String method) {
    final l10n = AppLocalizations.of(context)!;
    switch (method) {
      case 'left breast':
        return l10n.leftBreast;
      case 'right breast':
        return l10n.rightBreast;
      case 'both breasts':
        return l10n.bothBreasts;
      case 'bottle':
        return l10n.bottle;
      case 'spoon':
        return l10n.spoon;
      default:
        return method;
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      double? amount;
      if (_amountController.text.isNotEmpty) {
        amount = double.tryParse(_amountController.text);
      }
      
      // 确保结束时间不早于开始时间
      DateTime actualEndTime;
      if (widget.timer != null) {
        actualEndTime = DateTime.now();
      } else {
        actualEndTime = _endTime;
      }
      
      // 如果结束时间早于开始时间，自动调整
      if (actualEndTime.isBefore(_startTime)) {
        actualEndTime = _startTime.add(const Duration(minutes: 1));
      }
      
      if (widget.editItem != null) {
        final data = <String, dynamic>{
          'child': widget.childId,
          'start': DateTimeUtils.formatForApi(_startTime),
          'end': DateTimeUtils.formatForApi(actualEndTime),
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
        Fluttertoast.showToast(msg: l10n.feedingUpdated);
      } else {
        if (widget.timer != null) {
          await ApiService.addFeeding(
            widget.childId,
            DateTimeUtils.formatForApi(_startTime),
            DateTimeUtils.formatForApi(actualEndTime),
            _selectedType,
            _selectedMethod,
            timer: widget.timer!['id'] as int,
            amount: amount,
            amountUnit: 'ml',
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
        } else {
          await ApiService.addFeeding(
            widget.childId,
            DateTimeUtils.formatForApi(_startTime),
            DateTimeUtils.formatForApi(actualEndTime),
            _selectedType,
            _selectedMethod,
            amount: amount,
            amountUnit: 'ml',
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
        }
        Fluttertoast.showToast(msg: l10n.feedingRecorded);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? l10n.updateFailed : l10n.addFailed;
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg: ${l10n.noPermission}';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg: ${l10n.networkError}';
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '${l10n.edit}${l10n.feeding}' : '${l10n.add}${l10n.feeding}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(l10n.milkType),
            const SizedBox(height: 8),
            _buildOptions(_feedingTypes, _selectedType, (v) => setState(() => _selectedType = v), _getTypeName),
            const SizedBox(height: 16),
            _buildSection(l10n.feedingMethod),
            const SizedBox(height: 8),
            _buildOptions(_feedingMethods, _selectedMethod, (v) => setState(() => _selectedMethod = v), _getMethodName),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${l10n.amount} (ml)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? l10n.save : l10n.confirm),
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

  Widget _buildOptions(List<String> options, String selected, ValueChanged<String> onChanged, String Function(String) getName) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return ChoiceChip(
          label: Text(getName(option)),
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
  final Map<String, dynamic>? timer;
  const SleepOptions({
    super.key,
    required this.childId,
    required this.onSaved,
    this.editItem,
    this.timer,
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
    if (widget.timer != null) {
      final timer = widget.timer!;
      if (timer['start'] != null) {
        _startTime = DateTimeUtils.parseServerTime(timer['start']);
        _endTime = DateTime.now();
      }
    } else if (widget.editItem != null) {
      final item = widget.editItem!;
      _isNap = item['nap'] ?? false;
      if (item['start'] != null) {
        _startTime = DateTimeUtils.parseServerTime(item['start']);
      }
      if (item['end'] != null) {
        _endTime = DateTimeUtils.parseServerTime(item['end']);
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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      // 确保结束时间不早于开始时间
      DateTime actualEndTime;
      if (widget.timer != null) {
        actualEndTime = DateTime.now();
      } else {
        actualEndTime = _endTime;
      }
      
      // 如果结束时间早于开始时间，自动调整
      if (actualEndTime.isBefore(_startTime)) {
        actualEndTime = _startTime.add(const Duration(minutes: 1));
      }
      
      if (widget.editItem != null) {
        final data = <String, dynamic>{
          'child': widget.childId,
          'start': DateTimeUtils.formatForApi(_startTime),
          'end': DateTimeUtils.formatForApi(actualEndTime),
          'nap': _isNap,
        };
        if (_notesController.text.isNotEmpty) {
          data['notes'] = _notesController.text;
        }
        await ApiService.updateSleep(widget.editItem!['id'], data);
        Fluttertoast.showToast(msg: l10n.sleepUpdated);
      } else {
        if (widget.timer != null) {
          await ApiService.addSleep(
            widget.childId,
            DateTimeUtils.formatForApi(_startTime),
            DateTimeUtils.formatForApi(actualEndTime),
            timer: widget.timer!['id'] as int,
            nap: _isNap,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
        } else {
          await ApiService.addSleep(
            widget.childId,
            DateTimeUtils.formatForApi(_startTime),
            DateTimeUtils.formatForApi(actualEndTime),
            nap: _isNap,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
        }
        Fluttertoast.showToast(msg: l10n.sleepRecorded);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? l10n.updateFailed : l10n.addFailed;
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg: ${l10n.noPermission}';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg: ${l10n.networkError}';
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '${l10n.edit}${l10n.sleep}' : '${l10n.add}${l10n.sleep}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(l10n.nap),
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
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? l10n.save : l10n.confirm),
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

  String _getColorName(String color) {
    final l10n = AppLocalizations.of(context)!;
    switch (color) {
      case 'unknown':
        return l10n.unknown;
      case 'yellow':
        return l10n.yellow;
      case 'brown':
        return l10n.brown;
      case 'green':
        return l10n.green;
      case 'other':
        return l10n.other;
      default:
        return color;
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      if (widget.editItem != null) {
        final data = <String, dynamic>{
          'child': widget.childId,
          'time': widget.editItem!['time'] ?? DateTimeUtils.formatForApi(DateTime.now()),
          'wet': _wet,
          'solid': _solid,
          'color': _selectedColor,
        };
        if (_notesController.text.isNotEmpty) {
          data['notes'] = _notesController.text;
        }
        await ApiService.updateDiaper(widget.editItem!['id'], data);
        Fluttertoast.showToast(msg: l10n.deleteSuccess);
      } else {
        await ApiService.addDiaper(
          widget.childId,
          DateTimeUtils.formatForApi(DateTime.now()),
          _wet,
          _solid,
          _selectedColor,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        Fluttertoast.showToast(msg: l10n.diaper + l10n.success);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? l10n.updateFailed : l10n.addFailed;
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg: ${l10n.noPermission}';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg: ${l10n.networkError}';
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '${l10n.edit}${l10n.diaper}' : '${l10n.add}${l10n.diaper}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(l10n.type),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCheckbox(l10n.wet, _wet, (v) => setState(() => _wet = v ?? true)),
                ),
                Expanded(
                  child: _buildCheckbox(l10n.solid, _solid, (v) => setState(() => _solid = v ?? false)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(l10n.color),
            const SizedBox(height: 8),
            _buildOptions(_colors, _selectedColor, (v) => setState(() => _selectedColor = v)),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? l10n.save : l10n.confirm),
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
        return ChoiceChip(
          label: Text(_getColorName(option)),
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
  final Map<String, dynamic>? timer;
  const TummyTimeOptions({
    super.key,
    required this.childId,
    required this.onSaved,
    this.editItem,
    this.timer,
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
    if (widget.timer != null) {
      final timer = widget.timer!;
      if (timer['start'] != null) {
        _startTime = DateTimeUtils.parseServerTime(timer['start']);
        _endTime = DateTime.now();
      }
    } else if (widget.editItem != null) {
      final item = widget.editItem!;
      if (item['start'] != null) {
        _startTime = DateTimeUtils.parseServerTime(item['start']);
      }
      if (item['end'] != null) {
        _endTime = DateTimeUtils.parseServerTime(item['end']);
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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      // 确保结束时间不早于开始时间
      DateTime actualEndTime;
      if (widget.timer != null) {
        actualEndTime = DateTime.now();
      } else {
        actualEndTime = _endTime;
      }
      
      // 如果结束时间早于开始时间，自动调整
      if (actualEndTime.isBefore(_startTime)) {
        actualEndTime = _startTime.add(const Duration(minutes: 1));
      }
      
      if (widget.editItem != null) {
        final data = <String, dynamic>{
          'child': widget.childId,
          'start': DateTimeUtils.formatForApi(_startTime),
          'end': DateTimeUtils.formatForApi(actualEndTime),
        };
        if (_milestoneController.text.isNotEmpty) {
          data['milestone'] = _milestoneController.text;
        }
        if (_notesController.text.isNotEmpty) {
          data['notes'] = _notesController.text;
        }
        await ApiService.updateTummyTime(widget.editItem!['id'], data);
        Fluttertoast.showToast(msg: l10n.tummyTimeUpdated);
      } else {
        if (widget.timer != null) {
          await ApiService.addTummyTime(
            widget.childId,
            DateTimeUtils.formatForApi(_startTime),
            DateTimeUtils.formatForApi(actualEndTime),
            timer: widget.timer!['id'] as int,
            milestone: _milestoneController.text.isNotEmpty ? _milestoneController.text : null,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
        } else {
          await ApiService.addTummyTime(
            widget.childId,
            DateTimeUtils.formatForApi(_startTime),
            DateTimeUtils.formatForApi(actualEndTime),
            milestone: _milestoneController.text.isNotEmpty ? _milestoneController.text : null,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
        }
        Fluttertoast.showToast(msg: l10n.tummyTimeRecorded);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? l10n.updateFailed : l10n.addFailed;
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg: ${l10n.noPermission}';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg: ${l10n.networkError}';
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '${l10n.edit}${l10n.tummyTime}' : '${l10n.add}${l10n.tummyTime}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _milestoneController,
              decoration: InputDecoration(
                labelText: '${l10n.milestone} (${l10n.notes})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? l10n.save : l10n.confirm),
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
        _startTime = DateTimeUtils.parseServerTime(item['start']);
      }
      if (item['end'] != null) {
        _endTime = DateTimeUtils.parseServerTime(item['end']);
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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      double? amount;
      if (_amountController.text.isNotEmpty) {
        amount = double.tryParse(_amountController.text);
      }
      
      // 确保结束时间不早于开始时间
      DateTime actualEndTime = _endTime;
      if (actualEndTime.isBefore(_startTime)) {
        actualEndTime = _startTime.add(const Duration(minutes: 1));
      }
      
      if (widget.editItem != null) {
        final data = <String, dynamic>{
          'child': widget.childId,
          'start': DateTimeUtils.formatForApi(_startTime),
          'end': DateTimeUtils.formatForApi(actualEndTime),
        };
        if (amount != null) {
          data['amount'] = amount;
          data['amount_unit'] = 'ml';
        }
        if (_notesController.text.isNotEmpty) {
          data['notes'] = _notesController.text;
        }
        await ApiService.updatePumping(widget.editItem!['id'], data);
        Fluttertoast.showToast(msg: l10n.pumping + l10n.success);
      } else {
        await ApiService.addPumping(
          widget.childId,
          DateTimeUtils.formatForApi(_startTime),
          DateTimeUtils.formatForApi(actualEndTime),
          amount: amount,
          amountUnit: 'ml',
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        Fluttertoast.showToast(msg: l10n.pumping + l10n.success);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? l10n.updateFailed : l10n.addFailed;
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg: ${l10n.noPermission}';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg: ${l10n.networkError}';
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '${l10n.edit}${l10n.pumping}' : '${l10n.add}${l10n.pumping}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${l10n.amount} (ml)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? l10n.save : l10n.confirm),
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
    final l10n = AppLocalizations.of(context)!;
    if (_noteController.text.isEmpty) {
      Fluttertoast.showToast(msg: '${l10n.note}${l10n.error}');
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
        Fluttertoast.showToast(msg: l10n.note + l10n.success);
      } else {
        await ApiService.addNote(
          widget.childId,
          _noteController.text,
        );
        Fluttertoast.showToast(msg: l10n.note + l10n.success);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? l10n.updateFailed : l10n.addFailed;
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg: ${l10n.noPermission}';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg: ${l10n.networkError}';
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editItem != null ? '${l10n.edit}${l10n.note}' : '${l10n.add}${l10n.note}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.content,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? l10n.save : l10n.confirm),
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
    final l10n = AppLocalizations.of(context)!;
    if (_editingModel == null) {
      if (_weightController.text.isEmpty && 
          _heightController.text.isEmpty && 
          _headCircController.text.isEmpty &&
          _tempController.text.isEmpty) {
        Fluttertoast.showToast(msg: '${l10n.weight} / ${l10n.height} ${l10n.error}');
        return;
      }
    } else {
      bool hasInput = false;
      if (_editingModel == 'weight' && _weightController.text.isNotEmpty) hasInput = true;
      if (_editingModel == 'height' && _heightController.text.isNotEmpty) hasInput = true;
      if (_editingModel == 'head circumference' && _headCircController.text.isNotEmpty) hasInput = true;
      if (_editingModel == 'temperature' && _tempController.text.isNotEmpty) hasInput = true;
      if (!hasInput) {
        Fluttertoast.showToast(msg: l10n.weight + l10n.error);
        return;
      }
    }
    
    setState(() => _isLoading = true);
    try {
      if (widget.editItem != null && _editingModel != null) {
        final date = widget.editItem!['date'] ?? DateTimeUtils.formatDateOnly(DateTime.now());
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
            'time': time ?? DateTimeUtils.formatForApi(DateTime.now()),
            'temperature': double.parse(_tempController.text),
            'temperature_unit': 'C',
          };
          if (_notesController.text.isNotEmpty) {
            data['notes'] = _notesController.text;
          }
          await ApiService.updateTemperature(widget.editItem!['id'], data);
        }
        Fluttertoast.showToast(msg: l10n.weight + l10n.success);
      } else {
        final date = DateTimeUtils.formatDateOnly(DateTime.now());
        final time = DateTimeUtils.formatForApi(DateTime.now());
        
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
        
        Fluttertoast.showToast(msg: l10n.weight + l10n.success);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        String errorMsg = widget.editItem != null ? l10n.updateFailed : l10n.addFailed;
        if (e.toString().contains('403')) {
          errorMsg = '$errorMsg: ${l10n.noPermission}';
        } else if (e.toString().contains('DioException')) {
          errorMsg = '$errorMsg: ${l10n.networkError}';
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
    final l10n = AppLocalizations.of(context)!;
    String title = widget.editItem != null ? '${l10n.edit}${l10n.weight}' : '${l10n.add}${l10n.weight}';
    if (_editingModel == 'weight') title = '${l10n.edit}${l10n.weightKg}';
    if (_editingModel == 'height') title = '${l10n.edit}${l10n.heightCm}';
    if (_editingModel == 'head circumference') title = '${l10n.edit}${l10n.headCircumferenceCm}';
    if (_editingModel == 'temperature') title = '${l10n.edit}${l10n.temperatureC}';
    
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                decoration: InputDecoration(
                  labelText: '${l10n.weight} (kg)',
                  border: const OutlineInputBorder(),
                ),
              ),
            if (_editingModel == null || _editingModel == 'weight')
              const SizedBox(height: 16),
            if (_editingModel == null || _editingModel == 'height')
              TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${l10n.height} (cm)',
                  border: const OutlineInputBorder(),
                ),
              ),
            if (_editingModel == null || _editingModel == 'height')
              const SizedBox(height: 16),
            if (_editingModel == null || _editingModel == 'head circumference')
              TextField(
                controller: _headCircController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${l10n.headCircumference} (cm)',
                  border: const OutlineInputBorder(),
                ),
              ),
            if ((_editingModel == null || _editingModel == 'head circumference') && 
                (_editingModel == null || _editingModel == 'temperature'))
              const SizedBox(height: 16),
            if (_editingModel == null || _editingModel == 'temperature')
              TextField(
                controller: _tempController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${l10n.temperature} (°C)',
                  border: const OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.editItem != null ? l10n.save : l10n.confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

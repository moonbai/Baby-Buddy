import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:babybuddy_app/generated/app_localizations.dart';
import 'package:babybuddy_app/generated/app_localizations_en.dart';

class ChildSelect extends StatefulWidget {
  const ChildSelect({super.key});

  @override
  State<ChildSelect> createState() => _ChildSelectState();
}

class _ChildSelectState extends State<ChildSelect> {
  List children = [];
  bool _isLoading = true;
  String? _errorMessage;

  AppLocalizations get l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsEn();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService.getChildren();
      if (!mounted) return;
      setState(() {
        children = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: '${l10n.loadFailed}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectChild)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: load,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.reload),
              ),
            ],
          ),
        ),
      );
    }

    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                '暂无宝宝，请先在 Baby Buddy 服务器添加宝宝',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: load,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.reload),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: children.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (c, i) {
        final item = children[i];
        if (item is! Map) {
          return const SizedBox.shrink();
        }
        final firstName = (item['first_name'] ?? '').toString();
        final lastName = (item['last_name'] ?? '').toString();
        final birthDate = item['birth_date']?.toString();
        final fullName = '$firstName $lastName'.trim();
        final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            child: Text(initial, style: const TextStyle(fontSize: 18)),
          ),
          title: Text(
            fullName.isEmpty ? l10n.unknown : fullName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: birthDate != null && birthDate.isNotEmpty
              ? Text('${l10n.birthday}: $birthDate')
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final id = item['id'];
            if (id is! int) {
              Fluttertoast.showToast(msg: l10n.error);
              return;
            }
            await Storage.saveChildId(id);
            if (!mounted) return;
            Fluttertoast.showToast(
              msg: '${l10n.selectChild}: $fullName',
              backgroundColor: Colors.green,
            );
            Navigator.pop(context);
          },
        );
      },
    );
  }
}



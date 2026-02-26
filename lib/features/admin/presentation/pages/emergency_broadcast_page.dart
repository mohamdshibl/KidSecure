import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/broadcast_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class EmergencyBroadcastPage extends StatefulWidget {
  const EmergencyBroadcastPage({super.key});

  @override
  State<EmergencyBroadcastPage> createState() => _EmergencyBroadcastPageState();
}

class _EmergencyBroadcastPageState extends State<EmergencyBroadcastPage> {
  String _selectedTemplate = 'lockdown';
  List<BroadcastTarget> _selectedTargets = [BroadcastTarget.all];
  final TextEditingController _messageController = TextEditingController(
    text:
        'تنبيه هام: تم تفعيل بروتوكول الإغلاق الكلي للمدرسة فوراً. يرجى البقاء في أماكن آمنة حتى إشعار آخر.',
  );
  bool _isSending = false;

  final Map<String, Map<String, dynamic>> _templates = {
    'lockdown': {
      'icon': Icons.lock_outline_rounded,
      'title': 'إغلاق كلي',
      'color': const Color(0xFFEF4444),
      'message':
          'تنبيه هام: تم تفعيل بروتوكول الإغلاق الكلي للمدرسة فوراً. يرجى البقاء في أماكن آمنة حتى إشعار آخر.',
    },
    'evacuation': {
      'icon': Icons.fire_truck_rounded,
      'title': 'إخلاء / حريق',
      'color': const Color(0xFFF97316),
      'message':
          'تنبيه طوارئ: يرجى إخلاء المبنى فوراً والتوجه إلى نقاط التجمع المحددة. حافظ على الهدوء واتبع تعليمات فريق الطوارئ.',
    },
    'weather': {
      'icon': Icons.ac_unit_rounded,
      'title': 'أحوال جوية',
      'color': const Color(0xFF3B82F6),
      'message':
          'تنبيه جوي: نظراً لسوء الأحوال الجوية المتوقعة، يرجى الحذر واتباع إجراءات السلامة. سيتم إخطاركم بأي تحديثات لاحقاً.',
    },
    'alert': {
      'icon': Icons.campaign_rounded,
      'title': 'تنبيه عام',
      'color': const Color(0xFF8B5CF6),
      'message': 'تنبيه عام من إدارة المدرسة: [يرجى إدخال نص الرسالة هنا].',
    },
  };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onTemplateSelected(String key) {
    setState(() {
      _selectedTemplate = key;
      _messageController.text = _templates[key]!['message'];
    });
  }

  void _toggleTarget(BroadcastTarget target) {
    setState(() {
      if (target == BroadcastTarget.all) {
        _selectedTargets = [BroadcastTarget.all];
      } else {
        _selectedTargets.remove(BroadcastTarget.all);
        if (_selectedTargets.contains(target)) {
          _selectedTargets.remove(target);
          if (_selectedTargets.isEmpty)
            _selectedTargets = [BroadcastTarget.all];
        } else {
          _selectedTargets.add(target);
        }
      }
    });
  }

  Future<void> _sendEmergencyBroadcast() async {
    setState(() => _isSending = true);

    try {
      final user = context.read<AuthBloc>().state.user!;
      final repository = context.read<BroadcastRepository>();

      // In real scenario, we might send multiple messages or one with multiple tags
      // For this implementation, we send to the primary selected targets
      for (final target in _selectedTargets) {
        await repository.sendBroadcast(
          BroadcastMessage(
            id: '',
            title: 'طوارئ: ${_templates[_selectedTemplate]!['title']}',
            body: _messageController.text.trim(),
            target: target,
            createdAt: DateTime.now(),
            senderId: user.id,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال بلاغ الطوارئ بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ أثناء الإرسال: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'بث حالة طوارئ',
            style: GoogleFonts.notoKufiArabic(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_tethering_rounded,
                      color: Color(0xFFEF4444),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'بث مباشر',
                      style: GoogleFonts.notoKufiArabic(
                        color: const Color(0xFFEF4444),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadyBanner(),
              const SizedBox(height: 32),
              _buildSectionTitle('قوالب سريعة', 'اختر نوع الحالة'),
              const SizedBox(height: 16),
              _buildTemplatesGrid(),
              const SizedBox(height: 32),
              _buildSectionTitle('المستلمون', 'تحديد الجهات المعنية'),
              const SizedBox(height: 16),
              _buildRecipientsList(),
              const SizedBox(height: 32),
              _buildSectionTitle(
                'نص الرسالة',
                '${_messageController.text.length}/160 حرف',
              ),
              const SizedBox(height: 16),
              _buildMessageBox(),
              const SizedBox(height: 48),
              _buildSlideToSend(),
              const SizedBox(height: 20),
              _buildPrivacyWarning(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.radio_button_checked_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'النظام جاهز لإرسال تنبيهات فورية لكافة المسجلين.',
              style: GoogleFonts.notoKufiArabic(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoKufiArabic(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.notoKufiArabic(
            color: const Color(0xFF64748B),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final key = _templates.keys.elementAt(index);
        final template = _templates[key]!;
        final isSelected = _selectedTemplate == key;

        return GestureDetector(
          onTap: () => _onTemplateSelected(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? template['color'].withOpacity(0.1)
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? template['color']
                    : Colors.white.withOpacity(0.05),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: template['color'].withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  template['icon'],
                  color: isSelected
                      ? template['color']
                      : const Color(0xFF64748B),
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  template['title'],
                  style: GoogleFonts.notoKufiArabic(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipientsList() {
    final targets = {
      BroadcastTarget.all: 'الجميع',
      BroadcastTarget.parents: 'أولياء الأمور',
      BroadcastTarget.gateOfficers: 'المشرفين',
      BroadcastTarget.drivers: 'السائقين',
    };

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: targets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final target = targets.keys.elementAt(index);
          final label = targets[target]!;
          final isSelected = _selectedTargets.contains(target);

          return GestureDetector(
            onTap: () => _toggleTarget(target),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFEF4444)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.notoKufiArabic(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _messageController,
        maxLines: 4,
        maxLength: 160,
        style: GoogleFonts.notoKufiArabic(
          color: Colors.white,
          fontSize: 14,
          height: 1.6,
        ),
        decoration: InputDecoration(
          hintText: 'اكتب رسالة الطوارئ هنا...',
          hintStyle: GoogleFonts.notoKufiArabic(color: const Color(0xFF64748B)),
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSlideToSend() {
    return _EmergencySlider(
      onConfirm: _sendEmergencyBroadcast,
      isSending: _isSending,
    );
  }

  Widget _buildPrivacyWarning() {
    return Center(
      child: Text(
        'تحذير: هذا الإجراء سيقوم بإرسال تنبيهات حرجة فورية لـ 1,450 مستخدم',
        textAlign: TextAlign.center,
        style: GoogleFonts.notoKufiArabic(
          color: const Color(0xFFEF4444),
          fontSize: 10,
        ),
      ),
    );
  }
}

class _EmergencySlider extends StatefulWidget {
  final VoidCallback onConfirm;
  final bool isSending;

  const _EmergencySlider({required this.onConfirm, required this.isSending});

  @override
  State<_EmergencySlider> createState() => _EmergencySliderState();
}

class _EmergencySliderState extends State<_EmergencySlider>
    with SingleTickerProviderStateMixin {
  double _position = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_EmergencySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSending && !widget.isSending) {
      _animateTo(0);
    }
  }

  void _animateTo(double target) {
    _animation =
        Tween<double>(begin: _position, end: target).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        )..addListener(() {
          setState(() {
            _position = _animation.value;
          });
        });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxSlide = constraints.maxWidth - 64;

        return Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - (_position / (maxSlide * 0.7))).clamp(0.0, 1.0),
                child: Text(
                  'اسحب للإرسال الفوري',
                  style: GoogleFonts.notoKufiArabic(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                right: 4 + _position,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (widget.isSending) return;
                    setState(() {
                      _position = (_position - details.delta.dx).clamp(
                        0.0,
                        maxSlide,
                      );
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (widget.isSending) return;
                    if (_position >= maxSlide * 0.9) {
                      setState(() {
                        _position = maxSlide;
                      });
                      widget.onConfirm();
                    } else {
                      _animateTo(0);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFEF4444,
                          ).withOpacity(_position > 0 ? 0.6 : 0.4),
                          blurRadius: 10 + (_position / maxSlide) * 10,
                          spreadRadius: 1 + (_position / maxSlide) * 2,
                        ),
                      ],
                    ),
                    child: widget.isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

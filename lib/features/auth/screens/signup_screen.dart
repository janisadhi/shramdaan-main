import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_theme.dart';
import '../../profile/screens/help_support_screen.dart';
import '../services/auth_service.dart';
import '../widgets/auth_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _selectedGender;
  DateTime? _selectedDOB;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDOB) {
      setState(() => _selectedDOB = picked);
    }
  }

  Future<void> _signUp() async {
    final isFormValid = _formKey.currentState!.validate();

    if (_selectedDOB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return;
    }

    if (!isFormValid) {
      return;
    }

    setState(() => _isLoading = true);

    final user = await _authService.signUpWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _fullNameController.text.trim(),
      _phoneController.text.trim(),
      _selectedDOB!,
      _selectedGender,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign-up failed. The email may already be in use.'),
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.neutral,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.asset(
                                    'assets/icon.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Join shramdaan',
                                      style: textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Create your volunteer identity and start contributing.',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.78),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'Build impact,\none event at a time.',
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Create your account to discover nearby service, join causes, and grow with the community.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.86),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.14),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create account',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Set up your profile to start volunteering.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _fullNameController,
                                  decoration: _inputDecoration(
                                    label: 'Full name',
                                    hint: 'Your name',
                                    icon: Icons.person_outline,
                                  ),
                                  validator: (value) => value == null || value.isEmpty
                                      ? 'Please enter your name'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecoration(
                                    label: 'Email',
                                    hint: 'you@example.com',
                                    icon: Icons.email_outlined,
                                  ),
                                  validator: (value) => value == null || value.isEmpty
                                      ? 'Please enter an email'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDecoration(
                                    label: 'Phone number',
                                    hint: '98XXXXXXXX',
                                    icon: Icons.phone_outlined,
                                  ),
                                  validator: (value) => value == null || value.isEmpty
                                      ? 'Please enter a phone number'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedGender,
                                  decoration: _inputDecoration(
                                    label: 'Gender',
                                    hint: 'Select your gender',
                                    icon: Icons.wc_outlined,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                                    DropdownMenuItem(
                                      value: 'Female',
                                      child: Text('Female'),
                                    ),
                                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                                    DropdownMenuItem(
                                      value: 'Prefer not to say',
                                      child: Text('Prefer not to say'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _selectedGender = value),
                                  validator: (value) => value == null || value.isEmpty
                                      ? 'Please select your gender'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                InkWell(
                                  onTap: _pickDOB,
                                  borderRadius: BorderRadius.circular(18),
                                  child: InputDecorator(
                                    decoration: _inputDecoration(
                                      label: 'Date of birth',
                                      hint: 'Select your date of birth',
                                      icon: Icons.calendar_today_outlined,
                                    ),
                                    child: Text(
                                      _selectedDOB == null
                                          ? 'Select your date of birth'
                                          : DateFormat.yMMMMd().format(_selectedDOB!),
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: _selectedDOB == null
                                            ? AppColors.disabled
                                            : AppColors.textPrimary,
                                        fontWeight: _selectedDOB == null
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: _inputDecoration(
                                    label: 'Password',
                                    hint: 'At least 6 characters',
                                    icon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(
                                          () => _obscurePassword = !_obscurePassword,
                                        );
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) => value == null || value.length < 6
                                      ? 'Password must be at least 6 characters'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : _signUp,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Create Account'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account?',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Sign in'),
                                      ),
                                    ],
                                  ),
                                ),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const HelpSupportScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.help_outline_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Need help?'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

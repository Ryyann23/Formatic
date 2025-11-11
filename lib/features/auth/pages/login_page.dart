import 'package:flutter/material.dart';
import 'package:formatic/core/theme/button_styles.dart';
import 'package:formatic/core/utils/snackbar_utils.dart';
import 'package:formatic/features/home/pages/home_page.dart';
import 'package:formatic/services/auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const LoginPage({super.key, required this.onThemeToggle});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  // O telefone será editado apenas na tela de perfil
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  Future<void> _handleAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final authService = AuthService();

      if (_isLogin) {
        // Login
        final response = await authService.signIn(email, password);

        if (response.user != null) {
          if (!mounted) return;
          final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
          SnackbarUtils.showSuccess(context, 'Login realizado com sucesso!');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomePage(
                isDarkMode: isDarkTheme,
                onThemeToggle: widget.onThemeToggle,
              ),
            ),
          );
        }
      } else {
        // Cadastro
        final response = await authService.signUp(
          email,
          password,
          _nameController.text.trim(),
        );

        if (response.user != null) {
          // The profile is created server-side by a DB trigger. Proceed to
          // show success and switch to login. The trigger will insert a
          // `profiles` row with the new user's id automatically.
          if (!mounted) return;
          SnackbarUtils.showSuccess(context, 'Cadastro realizado com sucesso!');
          setState(() => _isLogin = true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Erro: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color mainColor = const Color(0xFF8B2CF5);
    final Color cardColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final Color accent = isDark ? Colors.white : mainColor;

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1B2E),
                    const Color(0xFF533483),
                    const Color(0xFF8B2CF5),
                  ]
                : [
                    const Color.fromARGB(255, 155, 30, 233), // Rosa
                    const Color(0xFF9C27B0), // Roxo
                    const Color(0xFF673AB7), // Roxo escuro
                  ],
          ),
        ),
        child: Column(
          children: [
            // Seção superior com logo e botão de tema
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  // Botão de alternância de tema
                  Positioned(
                    top: 50,
                    right: 20,
                    child: GestureDetector(
                      onTap: widget.onThemeToggle,
                      child: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  // Logo centralizada
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              size: 48,
                              color: mainColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Seção inferior com formulário
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          _isLogin ? 'Bem-vindo de volta!' : 'Crie sua conta',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin
                              ? 'Faça login para continuar'
                              : 'Preencha os dados para se cadastrar',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Campo adicional para cadastro: nome
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nome',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: mainColor,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF232B36)
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe o nome';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: mainColor,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF232B36)
                                : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe o e-mail';
                            }
                            if (!value.contains('@')) {
                              return 'E-mail inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: mainColor,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF232B36)
                                : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: mainColor,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a senha';
                            }
                            if (value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        // Seção apenas para login: lembrar de mim e esqueceu senha
                        if (_isLogin) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              // Checkbox "Lembrar de mim"
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: mainColor,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: Text(
                                  'Lembrar de mim',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Link "Esqueceu a senha?"
                              GestureDetector(
                                onTap: () {
                                  SnackbarUtils.showError(
                                    context,
                                    'Funcionalidade em desenvolvimento',
                                  );
                                },
                                child: Text(
                                  'Esqueceu a senha?',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: mainColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: purpleElevatedStyle(
                              radius: 25,
                              elevation: 2,
                            ),
                            onPressed: _loading ? null : _handleAuth,
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Entrar' : 'Cadastrar',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? 'Não tem conta?' : 'Já tem conta?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _isLogin = !_isLogin),
                              style: TextButton.styleFrom(
                                foregroundColor: mainColor,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Text(_isLogin ? 'Cadastre-se' : 'Entrar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

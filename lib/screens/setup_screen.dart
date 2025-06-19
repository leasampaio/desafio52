import 'package:flutter/material.dart';
import '../services/challenge_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _challengeService = ChallengeService();
  
  bool _isLoading = false;

  Future<void> _startChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final goalAmount = double.parse(_goalController.text.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.'));
      
      await _challengeService.createNewChallenge(
        goalAmount: goalAmount,
        goalDescription: _descriptionController.text,
        goalImagePath: null,
      );

      await NotificationService.scheduleWeeklyReminder();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar desafio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          'Configurar Desafio52',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.savings,
                        size: 60,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Desafio das 52 Semanas',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Economize dinheiro de forma gradual durante 1 ano inteiro e alcance sua meta financeira!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              Text(
                'Qual é sua meta financeira?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _goalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Valor da Meta (R\$)',
                  hintText: 'Ex: 5200,00',
                  prefixIcon: Icon(Icons.attach_money, color: Colors.blue.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o valor da meta';
                  }
                  try {
                    final amount = double.parse(value.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.'));
                    if (amount <= 0) {
                      return 'O valor deve ser maior que zero';
                    }
                  } catch (e) {
                    return 'Por favor, insira um valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              Text(
                'Descreva seu objetivo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descrição do Objetivo',
                  hintText: 'Ex: Viagem para o exterior, compra de um carro, reserva de emergência...',
                  prefixIcon: Icon(Icons.description, color: Colors.blue.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, descreva seu objetivo';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Iniciar Desafio!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 
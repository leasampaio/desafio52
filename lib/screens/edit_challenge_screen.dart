import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../services/challenge_service.dart';

class EditChallengeScreen extends StatefulWidget {
  final Challenge challenge;

  const EditChallengeScreen({super.key, required this.challenge});

  @override
  State<EditChallengeScreen> createState() => _EditChallengeScreenState();
}

class _EditChallengeScreenState extends State<EditChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _goalController;
  late TextEditingController _descriptionController;
  final _challengeService = ChallengeService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(
      text: widget.challenge.goalAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _descriptionController = TextEditingController(
      text: widget.challenge.goalDescription,
    );
  }

  Future<void> _updateChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final goalAmount = double.parse(
        _goalController.text
            .replaceAll(RegExp(r'[^\d,.]'), '')
            .replaceAll(',', '.'),
      );

      // Verifica se a meta mudou para recalcular as semanas
      bool goalChanged = goalAmount != widget.challenge.goalAmount;

      // Se a meta mudou e há progresso, pede confirmação
      if (goalChanged && widget.challenge.completedWeeks > 0) {
        final confirmed = await _showResetProgressDialog();
        if (!confirmed) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      Challenge updatedChallenge;

      if (goalChanged) {
        // Se a meta mudou, recalcula as semanas e reseta o progresso
        final newWeeks = Challenge.generateWeeks(goalAmount);

        updatedChallenge = widget.challenge.copyWith(
          goalAmount: goalAmount,
          goalDescription: _descriptionController.text,
          weeks: newWeeks, // Novas semanas sem progresso
        );
      } else {
        // Se apenas a descrição mudou
        updatedChallenge = widget.challenge.copyWith(
          goalDescription: _descriptionController.text,
        );
      }

      await _challengeService.saveChallenge(updatedChallenge);

      if (mounted) {
        // Mostra pop-up de parabéns
        await _showCongratulationsDialog(updatedChallenge);
        Navigator.of(
          context,
        ).pop(true); // Retorna true para indicar que houve mudança
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar desafio: $e'),
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

  Future<bool> _showResetProgressDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade600),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Confirmar Alteração',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Você tem progresso nas semanas do desafio atual.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Semanas completadas: ${widget.challenge.completedWeeks}/52',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      'Total economizado: R\$ ${widget.challenge.totalSaved.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ao alterar a meta, todo o progresso será perdido e você começará do zero.',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  Future<void> _showCongratulationsDialog(Challenge challenge) async {
    final completedWeeks = challenge.completedWeeks;
    final totalWeeks = challenge.weeks.length;
    final progressPercentage = (completedWeeks / totalWeeks * 100).round();
    final totalSaved = challenge.totalSaved;
    final goalChanged = challenge.goalAmount != widget.challenge.goalAmount;

    String congratsMessage;
    String motivationalMessage;
    IconData icon;
    Color iconColor;

    if (goalChanged) {
      // Mensagem especial quando a meta foi alterada
      congratsMessage = "Meta atualizada com sucesso! 🎯";
      motivationalMessage =
          "Sua nova meta é R\$ ${challenge.goalAmount.toStringAsFixed(2)}. Os valores semanais foram recalculados e seu progresso foi resetado. Hora de começar uma nova jornada!";
      icon = Icons.refresh;
      iconColor = Colors.blue.shade600;
    } else if (completedWeeks == 0) {
      congratsMessage = "Ótimo! Seu desafio foi atualizado! 🎯";
      motivationalMessage =
          "Agora você está pronto para começar sua jornada de economia. Cada pequeno passo conta!";
      icon = Icons.rocket_launch;
      iconColor = Colors.blue.shade600;
    } else if (progressPercentage < 25) {
      congratsMessage = "Parabéns! Você está no caminho certo! 🌟";
      motivationalMessage =
          "Você já completou $completedWeeks semanas e economizou R\$ ${totalSaved.toStringAsFixed(2)}. Continue assim!";
      icon = Icons.trending_up;
      iconColor = Colors.green.shade600;
    } else if (progressPercentage < 50) {
      congratsMessage = "Incrível! Você está fazendo um ótimo progresso! 🚀";
      motivationalMessage =
          "Já são $completedWeeks semanas concluídas ($progressPercentage% do desafio)! Você economizou R\$ ${totalSaved.toStringAsFixed(2)}. Continue firme!";
      icon = Icons.star;
      iconColor = Colors.orange.shade600;
    } else if (progressPercentage < 75) {
      congratsMessage = "Fantástico! Você está quase lá! 🎊";
      motivationalMessage =
          "Mais da metade do desafio concluído! $completedWeeks semanas e R\$ ${totalSaved.toStringAsFixed(2)} economizados. Você é incrível!";
      icon = Icons.emoji_events;
      iconColor = Colors.amber.shade600;
    } else if (progressPercentage < 100) {
      congratsMessage = "Sensacional! Você está na reta final! 🏆";
      motivationalMessage =
          "Faltam apenas ${totalWeeks - completedWeeks} semanas! Você já economizou R\$ ${totalSaved.toStringAsFixed(2)}. O sucesso está próximo!";
      icon = Icons.military_tech;
      iconColor = Colors.purple.shade600;
    } else {
      congratsMessage = "PARABÉNS! Você completou o desafio! 🎉";
      motivationalMessage =
          "Incrível! Você economizou R\$ ${totalSaved.toStringAsFixed(2)} em 52 semanas. Você é um verdadeiro campeão da economia!";
      icon = Icons.celebration;
      iconColor = Colors.green.shade600;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withOpacity(0.1),
                      iconColor.withOpacity(0.05),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(icon, size: 48, color: iconColor),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      congratsMessage,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      motivationalMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          'Editar Desafio',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                      Icon(Icons.edit, size: 60, color: Colors.blue.shade600),
                      const SizedBox(height: 15),
                      Text(
                        'Editar Desafio',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Você pode alterar sua meta financeira e a descrição do seu objetivo. Se alterar a meta, os valores semanais serão recalculados.',
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
                'Meta financeira',
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
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: Colors.blue.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.blue.shade600,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o valor da meta';
                  }
                  try {
                    final amount = double.parse(
                      value
                          .replaceAll(RegExp(r'[^\d,.]'), '')
                          .replaceAll(',', '.'),
                    );
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
                'Descrição do objetivo',
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
                  hintText:
                      'Ex: Viagem para o exterior, compra de um carro, reserva de emergência...',
                  prefixIcon: Icon(
                    Icons.description,
                    color: Colors.blue.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.blue.shade600,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, descreva seu objetivo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Aviso sobre recálculo
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ao alterar a meta, os valores semanais serão recalculados e seu progresso será resetado.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateChallenge,
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
                          'Salvar Alterações',
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

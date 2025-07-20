# Desafio52 - App de Economia Financeira

Um aplicativo Flutter para criar o hábito de economia durante 52 semanas (1 ano completo).

## 📱 Sobre o App

O **Desafio52** é um aplicativo que ajuda usuários a criarem um hábito de economia gradual ao longo de 52 semanas. O conceito é simples: o usuário define uma meta financeira total, e o app divide esse valor entre as 52 semanas do ano de forma progressiva.

### 🎯 Funcionalidades Principais

- **Configuração de Meta**: Defina o valor total que deseja economizar
- **Descrição do Objetivo**: Adicione uma descrição motivacional do seu objetivo
- **Cálculo Automático**: O app calcula automaticamente quanto economizar a cada semana
- **Acompanhamento de Progresso**: Veja seu progresso semanal e total
- **Marcação de Semanas**: Marque as semanas como concluídas conforme economiza
- **Edição de Desafio**: Altere sua meta ou descrição a qualquer momento
- **Reset do Desafio**: Possibilidade de recomeçar o desafio a qualquer momento

### 🏗️ Arquitetura do Projeto

```
lib/
├── models/
│   ├── week.dart           # Modelo para representar cada semana
│   └── challenge.dart      # Modelo para o desafio completo
├── services/
│   ├── challenge_service.dart    # Gerenciamento de dados do desafio
│   └── notification_service.dart # Serviço de notificações (simplificado)
├── screens/
│   ├── setup_screen.dart   # Tela de configuração inicial
│   ├── home_screen.dart    # Tela principal com progresso
│   └── edit_challenge_screen.dart # Tela de edição do desafio
└── main.dart              # Ponto de entrada do app
```

### 🔧 Como Funciona

1. **Tela Inicial (Splash)**: Verifica se já existe um desafio ativo
2. **Configuração**: Se não houver desafio, vai para tela de setup
3. **Setup**: Usuário define meta financeira e descrição do objetivo
4. **Cálculo**: App calcula valores semanais de forma progressiva
5. **Acompanhamento**: Usuário marca semanas como concluídas
6. **Progresso**: Visualização do progresso total e valores economizados

### 📊 Fórmula de Cálculo

O app usa uma progressão crescente baseada na meta definida:

- Total tradicional do desafio 52 semanas: R$ 1.378,00 (soma de 1 a 52)
- Fator de escala: `meta_do_usuario / 1378`
- Valor da semana N: `N * fator_de_escala`

### 🚀 Como Executar

1. **Pré-requisitos**:

   - Flutter SDK instalado
   - Android Studio ou VS Code com extensões Flutter
   - Emulador Android ou dispositivo físico

2. **Instalação**:
   ```bash
   git clone [seu-repositorio]
   cd desafio52
   flutter pub get
   flutter run
   ```

### 📦 Dependências

- **flutter**: Framework principal
- **cupertino_icons**: Ícones iOS

### 🎨 Design

- **Cores principais**: Tons de azul para confiança e estabilidade
- **Interface limpa**: Foco na usabilidade e clareza
- **Cards informativos**: Organização visual das informações
- **Feedback visual**: Indicadores de progresso e status

### 🔮 Funcionalidades Futuras

Para uma versão mais completa, você pode adicionar:

1. **Persistência de Dados**:

   ```yaml
   dependencies:
     shared_preferences: ^2.2.3
   ```

2. **Notificações Locais**:

   ```yaml
   dependencies:
     flutter_local_notifications: ^17.1.2
     permission_handler: ^11.3.1
   ```

3. **Seleção de Imagens**:

   ```yaml
   dependencies:
     image_picker: ^1.0.8
   ```

4. **Formatação de Moedas**:
   ```yaml
   dependencies:
     intl: ^0.19.0
   ```

### 📝 Estrutura de Dados

#### Week (Semana)

- `weekNumber`: Número da semana (1-52)
- `amount`: Valor a ser economizado
- `isCompleted`: Status de conclusão
- `completedDate`: Data de conclusão

#### Challenge (Desafio)

- `goalAmount`: Meta financeira total
- `startDate`: Data de início
- `weeks`: Lista das 52 semanas
- `goalDescription`: Descrição do objetivo
- `goalImagePath`: Caminho da imagem (opcional)

### 🎯 Objetivos de Aprendizado

Este projeto demonstra:

- Estruturação de um app Flutter
- Gerenciamento de estado com StatefulWidget
- Navegação entre telas
- Validação de formulários
- Persistência simples de dados
- Arquitetura MVC/Service
- Interface responsiva

### 📱 Screenshots

_[Aqui você pode adicionar screenshots do app funcionando]_

### 👥 Contribuição

Sinta-se à vontade para contribuir com melhorias:

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

### 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

---

**Desenvolvido com ❤️ usando Flutter**

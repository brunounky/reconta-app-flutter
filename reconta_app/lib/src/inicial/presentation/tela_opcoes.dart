import 'package:flutter/material.dart';
import 'package:reconta_app/src/auth/presentation/auth_service.dart';
import '../../cadastro/presentation/cad_produtos.dart';
import '../../contagem/presentation/selection.dart';
import '../../relatorios/presentation/relatorios_screen.dart';

class TelaOpcoes extends StatelessWidget {
  final String empresaId;
  final String? subEmpresaId;

  const TelaOpcoes({
    super.key,
    required this.empresaId,
    this.subEmpresaId,
  });

  @override
  Widget build(BuildContext context) {
    const Color corPrimaria = Color(0xFF0D47A1);
    const Color corTextoPrimario = Color(0xFF0D47A1);
    const Color corFundo = Color(0xFFF5F5F5);
    const Color corTextoAppBar = Colors.white;
    const Color corIconeAppBar = Colors.white;
    const Color corCard = Colors.white;

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          'Painel de Controle',
          style: TextStyle(
            color: corTextoAppBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: corPrimaria,
        elevation: 4.0,
        iconTheme: const IconThemeData(color: corIconeAppBar),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: corPrimaria,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: corPrimaria,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nome do Usuário',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'usuario@email.com',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Início'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Sair'),
              onTap: () {
                AuthService().signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
            children: [
              _buildDashboardCard(
                context: context,
                icon: Icons.timer_outlined,
                title: 'Contagem',
                color: corCard,
                iconColor: corTextoPrimario,
                textColor: corTextoPrimario,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectionScreen(
                        empresaId: empresaId,
                        subEmpresaId: subEmpresaId,
                      ),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                context: context,
                icon: Icons.analytics_outlined,
                title: 'Relatórios',
                color: corCard,
                iconColor: corTextoPrimario,
                textColor: corTextoPrimario,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RelatorioScreen(
                        empresaId: empresaId,
                        subEmpresaId: subEmpresaId,
                      ),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                context: context,
                icon: Icons.app_registration,
                title: 'Cadastros',
                color: corCard,
                iconColor: corTextoPrimario,
                textColor: corTextoPrimario,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CadProdutos(
                        empresaId: empresaId,
                        subEmpresaId: subEmpresaId,
                      ),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                context: context,
                icon: Icons.calendar_month_outlined,
                title: 'Agenda de Contagem',
                color: corCard,
                iconColor: corTextoPrimario,
                textColor: corTextoPrimario,
                onTap: () {
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5.0,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: iconColor),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
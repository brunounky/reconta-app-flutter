import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reconta_app/src/inicial/presentation/tela_opcoes.dart';

class SelecaoEmpresaScreen extends StatefulWidget {
  const SelecaoEmpresaScreen({super.key});

  @override
  State<SelecaoEmpresaScreen> createState() => _SelecaoEmpresaScreenState();
}

class _SelecaoEmpresaScreenState extends State<SelecaoEmpresaScreen> {
  String? _selectedEmpresaId;
  String? _selectedSubEmpresaId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Empresa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown para Empresas
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Empresa').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Erro ao carregar empresas');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                   return const Text('Nenhuma empresa encontrada.');
                }
                
                return DropdownButtonFormField<String>(
                  hint: const Text('Selecione a Empresa'),
                  value: _selectedEmpresaId,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedEmpresaId = newValue;
                      _selectedSubEmpresaId = null;
                    });
                  },
                  items: snapshot.data!.docs.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(doc['nome']),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),

            if (_selectedEmpresaId != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('SubEmpresa')
                    .where('empresaId', isEqualTo: _selectedEmpresaId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  return DropdownButtonFormField<String>(
                    hint: const Text('Selecione a Sub-Empresa (Opcional)'),
                    value: _selectedSubEmpresaId,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedSubEmpresaId = newValue;
                      });
                    },
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['nome']),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: (_selectedEmpresaId != null)
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TelaOpcoes(
                            empresaId: _selectedEmpresaId!,
                            subEmpresaId: _selectedSubEmpresaId,
                          ),
                        ),
                      );
                    }
                  : null,
              child: const Text('Acessar'),
            ),
          ],
        ),
      ),
    );
  }
}
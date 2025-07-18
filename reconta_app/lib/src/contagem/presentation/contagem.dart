// lib/src/contagem/presentation/contagem.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';

class Produto {
  final String id;
  final String nome;

  Produto({required this.id, required this.nome});

  factory Produto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Produto(
      id: doc.id,
      nome: data['Nome'] ?? '',
    );
  }
}

class ContagemScreen extends StatefulWidget {
  final String categoria;
  final String empresaId;
  final String? subEmpresaId;

  const ContagemScreen({
    super.key,
    required this.categoria,
    required this.empresaId,
    this.subEmpresaId,
  });

  @override
  State<ContagemScreen> createState() => _ContagemScreenState();
}

class _ContagemScreenState extends State<ContagemScreen> {
  List<Produto> _produtos = [];
  bool _isLoading = true;
  final Set<String> _produtosContados = {};
  final TextEditingController _searchController = TextEditingController();
  List<Produto> _filteredProdutos = [];

  @override
  void initState() {
    super.initState();
    _fetchProdutos();
    _searchController.addListener(_filterProdutos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProdutos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProdutos = _produtos.where((produto) {
        return produto.nome.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchProdutos() async {
    if (!mounted) return;
    try {
      Query query = FirebaseFirestore.instance
          .collection('Produtos')
          .where('empresaId', isEqualTo: widget.empresaId)
          .where('Categoria', isEqualTo: widget.categoria);

      if (widget.subEmpresaId != null) {
        query = query.where('subEmpresaId', isEqualTo: widget.subEmpresaId);
      }

      QuerySnapshot snapshot = await query.get();
      final produtosList =
          snapshot.docs.map((doc) => Produto.fromFirestore(doc)).toList();

      if (mounted) {
        setState(() {
          _produtos = produtosList;
          _filteredProdutos = produtosList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar produtos: $e')),
        );
      }
    }
  }

  void _showContagemPopup(Produto produto) {
    final sistemaController = TextEditingController();
    final fisicoController = TextEditingController();
    final diferencaNotifier = ValueNotifier(0);
    final formKey = GlobalKey<FormState>();

    void calcularDiferenca() {
      final sistema = int.tryParse(sistemaController.text) ?? 0;
      final fisico = _evaluateExpression(fisicoController.text);
      diferencaNotifier.value = fisico - sistema;
    }

    sistemaController.addListener(calcularDiferenca);
    fisicoController.addListener(calcularDiferenca);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          elevation: 8.0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    produto.nome,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: sistemaController,
                          labelText: 'Estoque Sistema',
                          isExpression: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: fisicoController,
                          labelText: 'Qtd. Físico (ex: 5*12+3)',
                          isExpression: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  ValueListenableBuilder<int>(
                    valueListenable: diferencaNotifier,
                    builder: (context, diferenca, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Diferença:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '$diferenca',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: diferenca == 0
                                    ? Colors.green
                                    : (diferenca > 0 ? Colors.blue : Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          final sistema = int.tryParse(sistemaController.text) ?? 0;
                          final fisico = _evaluateExpression(fisicoController.text);
                          final diferenca = fisico - sistema;

                          try {
                            await FirebaseFirestore.instance.collection('Contagens').add({
                              'empresaId': widget.empresaId,
                              'subEmpresaId': widget.subEmpresaId,
                              'produtoId': produto.id,
                              'produtoNome': produto.nome,
                              'estoqueSistema': sistema,
                              'quantidadeFisico': fisico,
                              'diferenca': diferenca,
                              'dataContagem': FieldValue.serverTimestamp(),
                            });

                            if (mounted) {
                              setState(() => _produtosContados.add(produto.id));
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Contagem registrada com sucesso!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao registrar: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('REGISTRAR'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      sistemaController.dispose();
      fisicoController.dispose();
      diferencaNotifier.dispose();
    });
  }

  int _evaluateExpression(String expression) {
    if (expression.isEmpty) return 0;
    try {
      // Remove caracteres não permitidos para segurança
      expression = expression.replaceAll(RegExp(r'[^0-9\+\-\*\/\.\(\)]'), '');
      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      return eval.round();
    } catch (e) {
      return 0;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required bool isExpression,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isExpression ? TextInputType.text : TextInputType.number,
      inputFormatters: isExpression ? [] : [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      validator: (value) {
        if (isExpression && value != null && value.isNotEmpty) {
          try {
            _evaluateExpression(value);
          } catch (e) {
            return 'Expressão inválida';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color corPrimaria = Color(0xFF0D47A1);
    const Color corTextoAppBar = Colors.white;
    const Color corIconeAppBar = Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoria,
          style: const TextStyle(color: corTextoAppBar, fontWeight: FontWeight.bold),
        ),
        backgroundColor: corPrimaria,
        iconTheme: const IconThemeData(color: corIconeAppBar),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar Produto por Nome',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProdutos.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Nenhum produto encontrado para este filtro.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _filteredProdutos.length,
                        itemBuilder: (context, index) {
                          final produto = _filteredProdutos[index];
                          final isContado = _produtosContados.contains(produto.id);
                          return Card(
                            elevation: 2.0,
                            margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: BorderSide(
                                color: isContado ? Colors.green.withOpacity(0.7) : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              title: Text(
                                produto.nome,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isContado ? Colors.grey.shade600 : Colors.black87,
                                ),
                              ),
                              trailing: Icon(
                                isContado ? Icons.check_circle : Icons.arrow_forward_ios,
                                color: isContado ? Colors.green : Colors.grey.shade400,
                                size: 20,
                              ),
                              onTap: () => _showContagemPopup(produto),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadProdutos extends StatefulWidget {
  const CadProdutos({super.key});

  @override
  State<CadProdutos> createState() => _CadProdutosState();
}

class _CadProdutosState extends State<CadProdutos> {
  final _formKey = GlobalKey<FormState>();
  final _codigoReferenciaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _subCategoriaController = TextEditingController();
  final _observacaoController = TextEditingController();

  int? _selectedPrioridade;
  final List<int> _prioridades = [1, 2, 7, 15, 30, 45];

  @override
  void dispose() {
    _codigoReferenciaController.dispose();
    _nomeController.dispose();
    _categoriaController.dispose();
    _subCategoriaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void _salvarProduto() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPrioridade == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione uma prioridade de contagem.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('Produtos').add({
          'CodigoReferencia': _codigoReferenciaController.text,
          'Nome': _nomeController.text,
          'Categoria': _categoriaController.text,
          'Sub_categoria': _subCategoriaController.text,
          'Observacoes': _observacaoController.text,
          'PrioridadeContagem': _selectedPrioridade,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produto salvo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao adicionar produto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const corPrimaria = Color(0xFF0D47A1);
    const corFundo = Colors.white;
    const corTextoAppBar = Colors.white;
    const corIconeAppBar = Colors.white;

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          'Cadastro de Produto',
          style: TextStyle(
            color: corTextoAppBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: corPrimaria,
        elevation: 2.0,
        iconTheme: const IconThemeData(color: corIconeAppBar),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextFormField(
                        controller: _codigoReferenciaController,
                        labelText: 'Código de Referência',
                        icon: Icons.qr_code_scanner,
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _nomeController,
                        labelText: 'Nome do Produto',
                        icon: Icons.shopping_bag_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o nome do produto.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _categoriaController,
                              labelText: 'Categoria',
                              icon: Icons.category_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Insira a categoria.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _subCategoriaController,
                              labelText: 'Sub-categoria',
                              icon: Icons.subdirectory_arrow_right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Prioridade de Contagem'),
                      _buildPrioridadeSelector(),
                      const SizedBox(height: 24),
                      _buildTextFormField(
                        controller: _observacaoController,
                        labelText: 'Observação (Opcional)',
                        icon: Icons.comment_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  onPressed: _salvarProduto,
                  icon: const Icon(Icons.save_alt_rounded, color: Colors.white),
                  label: const Text('Salvar Produto', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPrimaria,
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildPrioridadeSelector() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: _prioridades.map((dias) {
        final isSelected = _selectedPrioridade == dias;
        return ChoiceChip(
          label: Text('$dias dias'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedPrioridade = selected ? dias : null;
            });
          },
          backgroundColor: Colors.grey.shade100,
          selectedColor: const Color(0xFF0D47A1),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}

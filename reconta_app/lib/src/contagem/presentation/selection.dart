import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reconta_app/src/contagem/presentation/contagem.dart';

class SelectionScreen extends StatefulWidget {
  final String empresaId;
  final String? subEmpresaId;

  const SelectionScreen({
    super.key,
    required this.empresaId,
    this.subEmpresaId,
  });

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  List<String> _categorias = [];
  String? _selectedCategoria;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFiltros();
  }

  Future<void> _fetchFiltros() async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('Produtos')
          .where('empresaId', isEqualTo: widget.empresaId);

      if (widget.subEmpresaId != null) {
        query = query.where('subEmpresaId', isEqualTo: widget.subEmpresaId);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        Set<String> categoriasUnicas = {};
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final categoria = data['Categoria'] as String?;
          if (categoria != null && categoria.isNotEmpty) {
            categoriasUnicas.add(categoria);
          }
        }

        setState(() {
          _categorias = categoriasUnicas.toList()..sort();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao buscar filtros: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar filtros: $e')),
      );
    }
  }

  void _aplicarFiltro() {
    if (_selectedCategoria != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContagemScreen(
            categoria: _selectedCategoria!,
            empresaId: widget.empresaId,
            subEmpresaId: widget.subEmpresaId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecione pelo menos uma categoria.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color corPrimaria = Color(0xFF0D47A1);
    const Color corTextoPrimario = Color(0xFF0D47A1);
    const Color corFundo = Color(0xFFF5F5F5);
    const Color corTextoAppBar = Colors.white;
    const Color corIconeAppBar = Colors.white;

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          'Selecionar Filtros',
          style: TextStyle(
            color: corTextoAppBar,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: corPrimaria,
        elevation: 4.0,
        iconTheme: const IconThemeData(color: corIconeAppBar),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Filtros para Contagem',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: corTextoPrimario,
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _selectedCategoria,
                        hint: const Text('Selecione uma Categoria'),
                        isExpanded: true,
                        items: _categorias.map((String categoria) {
                          return DropdownMenuItem<String>(
                            value: categoria,
                            child: Text(categoria),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCategoria = newValue;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        validator: (value) =>
                            value == null ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _aplicarFiltro,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corPrimaria,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Filtrar e Iniciar Contagem',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
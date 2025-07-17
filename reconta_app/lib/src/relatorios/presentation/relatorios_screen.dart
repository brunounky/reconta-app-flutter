import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:reconta_app/src/relatorios/utils/pdf_generator.dart';

class RelatorioScreen extends StatefulWidget {
  final String empresaId;
  final String? subEmpresaId;

  const RelatorioScreen({
    super.key,
    required this.empresaId,
    this.subEmpresaId,
  });

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoria;
  List<String> _categorias = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _reportData = [];

  static const String _todosOsGrupos = 'Todos os Grupos';

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
  }

  Future<void> _fetchCategorias() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('Produtos')
          .where('empresaId', isEqualTo: widget.empresaId);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        final categoriasUnicas =
            snapshot.docs.map((doc) => doc['Categoria'] as String).toSet();
        setState(() {
          _categorias = [_todosOsGrupos, ...categoriasUnicas]..sort();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar categorias: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_selectedCategoria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um grupo.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _reportData = [];
    });

    try {
      final startOfDay =
          Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day));
      final endOfDay = Timestamp.fromDate(
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59));

      Query query = FirebaseFirestore.instance
          .collection('Contagens')
          .where('empresaId', isEqualTo: widget.empresaId)
          .where('dataContagem', isGreaterThanOrEqualTo: startOfDay)
          .where('dataContagem', isLessThanOrEqualTo: endOfDay);
      
      if (widget.subEmpresaId != null) {
        query = query.where('subEmpresaId', isEqualTo: widget.subEmpresaId);
      }

      final snapshot = await query.get();
      List<Map<String, dynamic>> allContagens = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
          .toList();

      List<Map<String, dynamic>> filteredReport = [];

      if (_selectedCategoria == _todosOsGrupos) {
        filteredReport = allContagens;
      } else {
         final productIds = await _getProductIdsForCategory(_selectedCategoria!);
         filteredReport = allContagens.where((contagem) => productIds.contains(contagem['produtoId'])).toList();
      }
      
      for (var i = 0; i < filteredReport.length; i++) {
        DocumentSnapshot productDoc = await FirebaseFirestore.instance.collection('Produtos').doc(filteredReport[i]['produtoId']).get();
        if(productDoc.exists){
            filteredReport[i]['CodigoReferencia'] = (productDoc.data() as Map<String, dynamic>)['CodigoReferencia'] ?? 'N/A';
        } else {
            filteredReport[i]['CodigoReferencia'] = 'N/A';
        }
      }


      setState(() {
        _reportData = filteredReport;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar relatório: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Set<String>> _getProductIdsForCategory(String category) async {
      Query productQuery = FirebaseFirestore.instance
        .collection('Produtos')
        .where('empresaId', isEqualTo: widget.empresaId)
        .where('Categoria', isEqualTo: category);
      
      final productSnapshot = await productQuery.get();
      return productSnapshot.docs.map((doc) => doc.id).toSet();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Contagem'),
        actions: [
          if (_reportData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
                final title = 'Relatório - $_selectedCategoria - $formattedDate';
                PdfGenerator.generateAndSharePdf(title, _reportData);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFilterSection(),
            const SizedBox(height: 20),
            _isLoading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : _buildReportResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data do Relatório',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategoria,
                  hint: const Text('Grupo'),
                  decoration: const InputDecoration(
                    labelText: 'Grupo',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: _categorias.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategoria = newValue;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.assessment),
              label: const Text('Gerar Relatório'),
              onPressed: _generateReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportResultSection() {
    if (_reportData.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'Nenhum dado encontrado para os filtros selecionados.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _reportData.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Card(
              elevation: 2,
              child: ListTile(
                dense: true,
                title: Row(
                  children: [
                    Expanded(flex: 2, child: Text('Código Ref.', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 4, child: Text('Nome do Produto', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Diferença', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  ],
                ),
              ),
            );
          }

          final item = _reportData[index - 1];
          final diferenca = item['diferenca'] as int;
          final corDiferenca = diferenca == 0 ? Colors.green : (diferenca > 0 ? Colors.blue : Colors.red);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Row(
                children: [
                  Expanded(flex: 2, child: Text(item['CodigoReferencia'].toString())),
                  Expanded(flex: 4, child: Text(item['produtoNome'].toString())),
                  Expanded(
                    flex: 1,
                    child: Text(
                      diferenca.toString(),
                      style: TextStyle(color: corDiferenca, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
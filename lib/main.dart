import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'shopping_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE shopping(id INTEGER PRIMARY KEY, name TEXT, quantity INTEGER, status BOOLEAN)',
      );
    },
    version: 1,
  );
  runApp(MyApp(
    database: database,
  ));
}

class MyApp extends StatelessWidget {
  final Future<Database> database;
  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Lista de Compras",
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: HomeScreen(database: database),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Future<Database> database;
  const HomeScreen({super.key, required this.database});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();
  bool _isPurchasedController = false;
  bool _isNotPurchasedController = false;
  List<Map<String, dynamic>> _shopping = [];
  String _filterStatus = 'Todos'; // 'Todos', 'Comprado', 'Não Comprado'
  String _sortOrder = 'Crescente'; // 'Crescente', 'Decrescente'

  @override
  void initState() {
    super.initState();
    refreshShoppingList();
  }

  Future<void> insertShopping(String name, int quantity, bool status) async {
    final Database db = await widget.database;
    await db.insert(
      'shopping',
      {
        'name': name,
        'quantity': quantity,
        'status': status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    refreshShoppingList();
  }

  Future<void> updateShopping(int id, String name, int quantity, bool status) async {
    final Database db = await widget.database;
    await db.update(
      'shopping',
      {
        'name': name,
        'quantity': quantity,
        'status': status,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    refreshShoppingList();
  }

  Future<void> deleteShopping(int id) async {
    final Database db = await widget.database;
    await db.delete(
      'shopping',
      where: 'id = ?',
      whereArgs: [id],
    );
    refreshShoppingList();
  }

  Future<void> refreshShoppingList() async {
    final Database db = await widget.database;
    final List<Map<String, dynamic>> maps = await db.query('shopping');

    List<Map<String, dynamic>> filteredList = maps.map((item) {
      return {
        'id': item['id'],
        'name': item['name'],
        'quantity': item['quantity'],
        'status': item['status'] == 1, // Converte de int para bool
      };
    }).toList();

    if (_filterStatus == 'Comprado') {
      filteredList = filteredList.where((item) => item['status'] == true).toList();
    } else if (_filterStatus == 'Não Comprado') {
      filteredList = filteredList.where((item) => item['status'] == false).toList();
    }

    if (_sortOrder == 'Crescente') {
      filteredList.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
    } else if (_sortOrder == 'Decrescente') {
      filteredList.sort((a, b) => b['name'].toString().toLowerCase().compareTo(a['name'].toString().toLowerCase()));
    }

    setState(() {
      _shopping = filteredList;
    });
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Todos'),
              onTap: () {
                setState(() {
                  _filterStatus = 'Todos';
                });
                refreshShoppingList();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Comprado'),
              onTap: () {
                setState(() {
                  _filterStatus = 'Comprado';
                });
                refreshShoppingList();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Não Comprado'),
              onTap: () {
                setState(() {
                  _filterStatus = 'Não Comprado';
                });
                refreshShoppingList();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Crescente'),
              onTap: () {
                setState(() {
                  _sortOrder = 'Crescente';
                });
                refreshShoppingList();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Decrescente'),
              onTap: () {
                setState(() {
                  _sortOrder = 'Decrescente';
                });
                refreshShoppingList();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Compras"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () => _showFilterOptions(context),
          ),
          IconButton(
            icon: Icon(Icons.sort_by_alpha),
            onPressed: () => _showSortOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: "Nome do item",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Quantidade de item",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          CheckboxListTile(
            title: Text('Comprado'),
            value: _isPurchasedController,
            onChanged: (newValue) {
              setState(() {
                _isPurchasedController = newValue!;
              });
            },
          ),
          CheckboxListTile(
            title: Text('Não Comprado'),
            value: _isNotPurchasedController,
            onChanged: (newValue) {
              setState(() {
                _isNotPurchasedController = newValue!;
              });
            },
          ),
          ElevatedButton(
            onPressed: () async {
              await insertShopping(
                _nameController.text,
                int.tryParse(_quantityController.text) ?? 0,
                _isPurchasedController,
              );
              _nameController.clear();
              _quantityController.clear();
              setState(() {
                _isPurchasedController = false;
              });
            },
            child: Text("Adicionar Compra"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _shopping.length,
              itemBuilder: (context, index) {
                final shopping = _shopping[index];
                return ListTile(
                  title: Text(shopping['name']),
                  subtitle: Row(
                    children: [
                      Text('Quantidade: ${shopping['quantity']}'),
                      SizedBox(width: 10), // Espaço entre os elementos
                      Text('Status: ${shopping['status'] ? 'Comprado' : 'Não comprado'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              TextEditingController _editNameController = TextEditingController(
                                  text: shopping['name']);
                              TextEditingController _editQuantityController = TextEditingController(
                                  text: shopping['quantity'].toString());
                              bool _editStatus = shopping['status'];
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: Text("Editar Compra"),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: _editNameController,
                                          decoration: InputDecoration(
                                            hintText: "Nome do Item",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        TextField(
                                          controller: _editQuantityController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: "Quantidade",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        CheckboxListTile(
                                          title: Text('Comprado'),
                                          value: _editStatus,
                                          onChanged: (newValue) {
                                            setState(() {
                                              _editStatus = newValue!;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          await updateShopping(
                                            shopping['id'],
                                            _editNameController.text,
                                            int.tryParse(_editQuantityController.text) ?? 0,
                                            _editStatus,
                                          );
                                          Navigator.pop(context);
                                          refreshShoppingList();
                                        },
                                        child: Text("Atualizar"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        icon: Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () async {
                          await deleteShopping(shopping['id']);
                          refreshShoppingList();
                        },
                        icon: Icon(Icons.delete),
                      ),
                    ],
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

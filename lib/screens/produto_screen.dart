import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projeto/_core/colors.dart';
import 'package:uuid/uuid.dart';
import '../firestore/helpers/enum_order.dart';
import '../firestore/models/listin.dart';
import '../firestore/models/produto.dart';
import '../firestore/models/list_tile_produto.dart';

class ProdutoScreen extends StatefulWidget {
  final Listin listin;

  const ProdutoScreen({super.key, required this.listin});

  @override
  State<ProdutoScreen> createState() => _ProdutoScreenState();
}

class _ProdutoScreenState extends State<ProdutoScreen> {
  List<Produto> listaProdutosPlanejados = [];
  List<Produto> listaProdutosPegos = [];

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  late StreamSubscription listener;

  OrdemProduto ordenacao = OrdemProduto.name;
  bool isDecrescente = false;

  @override
  void initState() {
    setupListeners();
    super.initState();
  }

  @override
  void dispose() {
    listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.listin.name,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          PopupMenuButton(
            color: Colors.white,
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: OrdemProduto.name,
                  child: Text('Ordenar por nome'),
                ),
                const PopupMenuItem(
                  value: OrdemProduto.amount,
                  child: Text('Ordenar por quantidade'),
                ),
                const PopupMenuItem(
                  value: OrdemProduto.price,
                  child: Text('Ordenar por preço'),
                ),
              ];
            },
            onSelected: (value) {
              setState(() {
                if (ordenacao == value) {
                  isDecrescente = !isDecrescente;
                } else {
                  ordenacao = value;
                }
              });
              refresh();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showFormModal();
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: RefreshIndicator(
        backgroundColor: MyColors.brown,
        color: Colors.white,
        onRefresh: () {
          return refresh();
        },
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  Text(
                    "R\$${calcularTotal().toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 42),
                  ),
                  const Text(
                    "total previsto para essa compra",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Divider(thickness: 2),
            ),
            const Text(
              "Produtos Planejados",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Column(
              children: List.generate(listaProdutosPlanejados.length, (index) {
                Produto produto = listaProdutosPlanejados[index];
                return ListTileProduto(
                  produto: produto,
                  isComprado: false,
                  showModal: showFormModal,
                  iconClick: alternarComprado,
                  trailClick: removerProduto,
                );
              }),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Divider(thickness: 2),
            ),
            const Text(
              "Produtos Comprados",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Column(
              children: List.generate(listaProdutosPegos.length, (index) {
                Produto produto = listaProdutosPegos[index];
                return ListTileProduto(
                  produto: produto,
                  isComprado: true,
                  showModal: showFormModal,
                  iconClick: alternarComprado,
                  trailClick: removerProduto,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  showFormModal({Produto? model}) {
    // Labels à serem mostradas no Modal
    String labelTitle = "Adicionar Produto";
    String labelConfirmationButton = "Salvar";
    String labelSkipButton = "Cancelar";

    // Controlador dos campos do produto
    TextEditingController nameController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    TextEditingController priceController = TextEditingController();

    bool isComprado = false;

    // Caso esteja editando
    if (model != null) {
      labelTitle = "Editando ${model.name}";
      nameController.text = model.name;

      if (model.price != null) {
        priceController.text = model.price.toString();
      }

      if (model.amount != null) {
        amountController.text = model.amount.toString();
      }

      isComprado = model.isComprado;
    }

    // Função do Flutter que mostra o modal na tela
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Define que as bordas verticais serão arredondadas
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(32.0),

          // Formulário com Título, Campo e Botões
          child: ListView(
            children: [
              Text(labelTitle,
                  style: Theme.of(context).textTheme.headlineSmall),
              TextFormField(
                controller: nameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  label: Text("Nome do Produto*"),
                  icon: Icon(Icons.abc_rounded),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                decoration: const InputDecoration(
                  label: Text("Quantidade"),
                  icon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  label: Text("Preço Unitario"),
                  icon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(labelSkipButton),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Criar um objeto Produto com as infos
                      Produto produto = Produto(
                        id: const Uuid().v1(),
                        name: nameController.text,
                        isComprado: isComprado,
                      );

                      // Usar id do model
                      if (model != null) {
                        produto.id = model.id;
                      }

                      if (amountController.text != "") {
                        produto.amount = double.parse(amountController.text);
                      }

                      if (priceController.text != "") {
                        produto.price = double.parse(priceController.text);
                      }
                      //Salvar no FIrestore
                      firestore
                          .collection('listins')
                          .doc(widget.listin.id)
                          .collection('produtos')
                          .doc(produto.id)
                          .set(produto.toMap());
                      // Fechar o Modal
                      Navigator.pop(context);
                    },
                    child: Text(labelConfirmationButton),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  refresh({QuerySnapshot<Map<String, dynamic>>? snapshot}) async {
    List<Produto> temp = [];

    snapshot ??= await firestore
        .collection('listins')
        .doc(widget.listin.id)
        .collection('produtos')
        .orderBy(ordenacao.name, descending: isDecrescente)
        .get();

    for (var doc in snapshot.docs) {
      Produto produto = Produto.fromMap(doc.data());
      temp.add(produto);
    }
    filtrarProdutos(temp);
  }

  filtrarProdutos(List<Produto> listaProdutos) {
    List<Produto> tempPlanjados = [];
    List<Produto> tempComprados = [];

    for (var produto in listaProdutos) {
      if (produto.isComprado) {
        tempComprados.add(produto);
      } else {
        tempPlanjados.add(produto);
      }
    }
    setState(() {
      listaProdutosPegos = tempComprados;
      listaProdutosPlanejados = tempPlanjados;
    });
  }

  alternarComprado(Produto produto) async {
    produto.isComprado = !produto.isComprado;

    await firestore
        .collection('listins')
        .doc(widget.listin.id)
        .collection('produtos')
        .doc(produto.id)
        .update({'isComprado': produto.isComprado});
  }

  setupListeners() {
    listener = firestore
        .collection('listins')
        .doc(widget.listin.id)
        .collection('produtos')
        .orderBy(ordenacao.name, descending: isDecrescente)
        .snapshots()
        .listen((snapshot) {
      refresh(snapshot: snapshot);
    });
  }

  removerProduto(Produto produto) async{
    await firestore
        .collection('listins')
        .doc(widget.listin.id)
        .collection('produtos')
        .doc(produto.id)
        .delete();
  }

  calcularTotal () {
    double precoTotal = 0;

    for (Produto produto in listaProdutosPegos) {
      if (produto.amount != null && produto.price != null) {
        precoTotal += (produto.amount! * produto.price!);
      }
    }
    return precoTotal;
  }
}

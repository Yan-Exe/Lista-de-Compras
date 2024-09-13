import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projeto/authentication/service/auth_service.dart';
import 'package:projeto/screens/produto_screen.dart';
import 'package:uuid/uuid.dart';
import '../firestore/models/listin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Listin> listListins = [];

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    refresh();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.brown,
        width: 180,
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sair', style: TextStyle(color: Colors.white),),
              onTap: () {
                AuthService().deslogar();
              },
            )
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Listin - Feira Colaborativa"),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
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
      body: (listListins.isEmpty)
          ? const Center(
              child: Text(
                "Nenhuma lista ainda.\nVamos criar a primeira?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : RefreshIndicator(
              backgroundColor: Colors.black,
              color: Colors.white,
              onRefresh: () {
                return refresh();
              },
              child: ListView(
                children: List.generate(
                  listListins.length,
                  (index) {
                    Listin model = listListins[index];
                    return Dismissible(
                      key: ValueKey<Listin>(model),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 30.0),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (direction) {
                        remove(model);
                      },
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ProdutoScreen(listin: model)));
                        },
                        onLongPress: () {
                          showFormModal(model: model);
                        },
                        leading: const Icon(Icons.list_alt_rounded),
                        title: Text(model.name),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  showFormModal({Listin? model}) {
    // Labels à serem mostradas no Modal
    String title = "Adicionar Listin";
    String confirmationButton = "Salvar";
    String skipButton = "Cancelar";

    // Controlador do campo que receberá o nome do Listin
    TextEditingController nameController = TextEditingController();

    if (model != null) {
      title = 'Editando ${model.name}';
      nameController.text = model.name;
    }

    // Função do Flutter que mostra o modal na tela
    showModalBottomSheet(
      context: context,

      // Define que as bordas verticais serão arredondadas
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(32.0),

          // Formulário com Título, Campo e Botões
          child: ListView(
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              TextFormField(
                controller: nameController,
                decoration:
                    const InputDecoration(label: Text("Nome do Listin")),
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
                    child: Text(skipButton),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        //Criar objeto com as infos
                        Listin listin = Listin(
                          id: const Uuid().v1(),
                          name: nameController.text,
                        );

                        if (model != null) {
                          listin.id = model.id;
                        }

                        //Salvar no Firestore
                        firestore
                            .collection('listins')
                            .doc(listin.id)
                            .set(listin.toMap());
                        //Atualizar lista
                        refresh();
                        //Fechar o Modal
                        Navigator.pop(context);
                      },
                      child: Text(confirmationButton)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  refresh() async {
    List<Listin> temp = [];
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await firestore.collection('listins').get();

    for (var doc in snapshot.docs) {
      temp.add(Listin.fromMap(doc.data()));
    }
    setState(() {
      listListins = temp;
    });
  }

  void remove(Listin model) {
    firestore.collection('listins').doc(model.id).delete();
    refresh();
  }
}

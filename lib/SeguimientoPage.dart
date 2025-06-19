import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'MyAppState.dart';

String createTweetMutation = """
mutation CreateTweet(\$contenido: String!, \$futbolista: String!, \$foto: String) {
  createTweet(contenido: \$contenido, futbolista: \$futbolista, foto: \$foto) {
    tweet {
      id
      contenido
      futbolista
      foto
    }
  }
}
""";

class SeguimientoPage extends StatelessWidget {
  final TextEditingController contenidoController = TextEditingController();
  final TextEditingController futbolistaController = TextEditingController();
  final TextEditingController fotoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.token.isEmpty) {
      return const Center(child: Text('No login yet.'));
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bienvenido: ${appState.username}"),
            const SizedBox(height: 20),
            Text("Crear nuevo tweet"),
            const SizedBox(height: 20),

            // Contenido del tweet
            TextFormField(
              keyboardType: TextInputType.text,
              controller: contenidoController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9 .,]")),
              ],
              decoration: const InputDecoration(
                labelText: 'Contenido',
                border: OutlineInputBorder(),
                hintText: 'Escribe el contenido del tweet',
              ),
            ),
            const SizedBox(height: 20),

            // Futbolista relacionado con el tweet
            TextFormField(
              keyboardType: TextInputType.text,
              controller: futbolistaController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ]")),
              ],
              decoration: const InputDecoration(
                labelText: 'Futbolista',
                border: OutlineInputBorder(),
                hintText: 'Nombre del futbolista',
              ),
            ),
            const SizedBox(height: 20),

            // Foto del tweet (opcional)
            /*TextFormField(
              keyboardType: TextInputType.url,
              controller: fotoController,
              decoration: const InputDecoration(
                labelText: 'URL de la Foto (opcional)',
                border: OutlineInputBorder(),
                hintText: 'https://example.com/foto.jpg',
              ),
            ),
            const SizedBox(height: 20),*/

            // Botón de guardar tweet
            Mutation(
              options: MutationOptions(
                document: gql(createTweetMutation),
                update: (cache, result) => cache,
                onCompleted: (result) {
                  if (result == null) {
                    print('Completado con errores');
                  } else {
                    print('Tweet creado:');
                    print(result);

                    Alert(
                      context: context,
                      type: AlertType.success,
                      title: appState.username,
                      desc: "Tu tweet ha sido registrado correctamente.",
                      buttons: [
                        DialogButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Aceptar",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                      ],
                    ).show();
                  }
                },
                onError: (error) {
                  print('Error:');
                  appState.error =
                      error?.graphqlErrors[0].message ?? "Error desconocido";

                  Alert(
                    context: context,
                    type: AlertType.error,
                    title: appState.username,
                    desc: appState.error,
                    buttons: [
                      DialogButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Aceptar",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ],
                  ).show();
                },
              ),
              builder: (runMutation, result) {
                return ElevatedButton(
                  onPressed: () {
                    runMutation({
                      "contenido": contenidoController.text,
                      "futbolista": futbolistaController.text,
                      "foto": fotoController.text.isNotEmpty
                          ? fotoController.text
                          : null,
                    });
                  },
                  child: const Text('Guardar Tweet'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

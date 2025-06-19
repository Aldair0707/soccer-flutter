import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import "MyAppState.dart";

String loginPostMutation = """
mutation TokenAuth(\$username : String!,  \$password : String!) {
  tokenAuth(
    username: \$username 
    password: \$password 
  ) {
    token
  }
}
""";

String createPostMutation = """
mutation CreateUser(\$email : String!,  \$password : String!, \$username : String!) {
  createUser(
    email: \$email 
    password: \$password 
    username: \$username 
  ) {
    user {
      id
      email
      username
    }
  }
}
""";

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Controladores para el registro
  TextEditingController createEmailController = TextEditingController();
  TextEditingController createPasswordController = TextEditingController();
  TextEditingController createUserController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    final _formKey1 = GlobalKey<FormState>();
    final _formKey2 = GlobalKey<FormState>();

    ThemeData darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      primaryColor: Colors.deepPurple,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[900],
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
      textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );

    // Función para mostrar alert con texto blanco
    void showWhiteTextAlert({
      required String title,
      required String desc,
      required AlertType type,
    }) {
      Alert(
        context: context,
        type: type,
        title: title,
        desc: desc,
        style: AlertStyle(
          titleStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          descStyle: TextStyle(color: Colors.white, fontSize: 16),
          backgroundColor: Colors.grey[900],
        ),
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Aceptar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ).show();
    }

    // Si el usuario ya tiene token, mostrar la pantalla de bienvenida
    if (appState.token.isNotEmpty) {
      return Theme(
        data: darkTheme,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "⚽ Bienvenido ${appState.username} ⚽",
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.logout),
                onPressed: () {
                  showWhiteTextAlert(
                    title: appState.username,
                    desc: "Tu sesión se ha cerrado correctamente.",
                    type: AlertType.info,
                  );
                  setState(() {
                    appState.username = "";
                    appState.token = "";
                  });
                },
                label: Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Theme(
      data: darkTheme,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LOGIN FORM
              Form(
                key: _formKey1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "⚽ Inicia sesión",
                      style: TextStyle(fontSize: 22, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: userNameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person, color: Colors.white70),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese su usuario' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock, color: Colors.white70),
                      ),
                      obscureText: true,
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese su contraseña' : null,
                    ),
                    const SizedBox(height: 20),
                    Mutation(
                      options: MutationOptions(
                        document: gql(loginPostMutation),
                        onCompleted: (result) {
                          if (result != null) {
                            setState(() {
                              appState.username = userNameController.text;
                              appState.token = result["tokenAuth"]["token"]
                                  .toString();
                              appState.selectedIndex = 1;
                            });

                            showWhiteTextAlert(
                              title: "⚽¡Bienvenido!⚽",
                              desc: "Inicio de sesión correcto.",
                              type: AlertType.success,
                            );
                          }
                        },
                        onError: (error) {
                          appState.error = error!.graphqlErrors[0].message
                              .toString();
                          showWhiteTextAlert(
                            title: "Error",
                            desc: appState.error,
                            type: AlertType.error,
                          );
                        },
                      ),
                      builder: (runMutation, result) {
                        return ElevatedButton.icon(
                          icon: Icon(Icons.login),
                          onPressed: () {
                            if (_formKey1.currentState!.validate()) {
                              runMutation({
                                "username": userNameController.text,
                                "password": passwordController.text,
                              });
                            }
                          },
                          label: Text("Iniciar sesión"),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 40, color: Colors.white30),

              // CREATE ACCOUNT
              Form(
                key: _formKey2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "⚽ Crear cuenta",
                      style: TextStyle(fontSize: 22, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: createEmailController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email, color: Colors.white70),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese su correo' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: createUserController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario',
                        prefixIcon: Icon(
                          Icons.person_add,
                          color: Colors.white70,
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese un usuario' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: createPasswordController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.white70,
                        ),
                      ),
                      obscureText: true,
                      validator: (value) =>
                          value!.isEmpty ? 'Ingrese su contraseña' : null,
                    ),
                    const SizedBox(height: 20),
                    Mutation(
                      options: MutationOptions(
                        document: gql(createPostMutation),
                        onCompleted: (result) {
                          if (result != null) {
                            appState.username = createUserController.text;
                            userNameController.text = appState.username;

                            createEmailController.clear();
                            createUserController.clear();
                            createPasswordController.clear();

                            showWhiteTextAlert(
                              title: "¡Registrado!",
                              desc: "Puedes iniciar sesión ahora.",
                              type: AlertType.success,
                            );
                          }
                        },
                        onError: (error) {
                          appState.error = error!.graphqlErrors[0].message
                              .toString();
                          showWhiteTextAlert(
                            title: "Error al crear usuario",
                            desc: appState.error,
                            type: AlertType.error,
                          );
                        },
                      ),
                      builder: (runMutation, result) {
                        return ElevatedButton.icon(
                          icon: Icon(Icons.person_add_alt_1),
                          onPressed: () {
                            if (_formKey2.currentState!.validate()) {
                              runMutation({
                                "email": createEmailController.text,
                                "username": createUserController.text,
                                "password": createPasswordController.text,
                              });
                            }
                          },
                          label: Text("Crear cuenta"),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

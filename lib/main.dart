import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'LoginPage.dart'; // Página de login
import 'LogsPage.dart'; // Página para mostrar los tweets
import 'SeguimientoPage.dart'; // Página para crear un tweet
//import 'ProfilePage.dart'; // Página para el perfil del usuario
import 'MyAppState.dart'; // Estado global de la app

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'SoccerHub ⚽',
        themeMode: ThemeMode.dark,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurpleAccent,
            brightness: Brightness.dark,
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(fontSize: 16),
          ),
        ),
        home: const MyHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();

    final authLink = AuthLink(
      getToken: () async {
        print('Token: ${appState.token}');
        return 'JWT ${appState.token}';
      },
    );

    final httpLink = authLink.concat(
      HttpLink(
        'https://soccerhub-graphql.onrender.com/graphql/',
      ), // La URL de tu API GraphQL
    );

    final client = ValueNotifier<GraphQLClient>(
      GraphQLClient(link: httpLink, cache: GraphQLCache()),
    );

    Widget page;
    switch (appState.selectedIndex) {
      case 0:
        page = LoginPage();
        break;
      case 1:
        page = LogsPage(); // Página que muestra los tweets
        break;
      case 2:
        page = SeguimientoPage(); // Página para crear un tweet
        break;
      case 3:
        page = LoginPage(); // Página de perfil (ajusta según tu necesidad)
        break;
      default:
        throw UnimplementedError(
          'No widget para índice ${appState.selectedIndex}',
        );
    }

    var mainArea = ColoredBox(
      color: Theme.of(context).colorScheme.background,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: page,
      ),
    );

    return GraphQLProvider(
      client: client,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 450) {
              return Column(
                children: [
                  Expanded(child: mainArea),
                  SafeArea(
                    child: BottomNavigationBar(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedItemColor: Theme.of(context).colorScheme.primary,
                      unselectedItemColor: Colors.grey[500],
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.login),
                          label: 'Login',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.list),
                          label: 'Tweets',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.add),
                          label: 'Crear Tweet',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.account_circle),
                          label: 'Perfil',
                        ),
                      ],
                      currentIndex: appState.selectedIndex,
                      onTap: (value) {
                        setState(() {
                          appState.selectedIndex = value;
                        });
                      },
                    ),
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  SafeArea(
                    child: NavigationRail(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedIconTheme: IconThemeData(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      selectedLabelTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      extended: constraints.maxWidth >= 600,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.login),
                          label: Text('Login'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.list),
                          label: Text('Tweets'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.add),
                          label: Text('Crear Tweet'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.account_circle),
                          label: Text('Perfil'),
                        ),
                      ],
                      selectedIndex: appState.selectedIndex,
                      onDestinationSelected: (value) {
                        setState(() {
                          appState.selectedIndex = value;
                        });
                      },
                    ),
                  ),
                  Expanded(child: mainArea),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

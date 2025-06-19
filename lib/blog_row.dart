import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

String createReactionMutation = """
mutation CreateReaction(\$tweetId : Int!, \$reactionType: String!) {
  createReaction(
    tweetId: \$tweetId,
    reactionType: \$reactionType
  ) {
    reaction {
      id
      reactionType
      user {
        username
      }
    }
  }
}
""";

class BlogRow extends StatefulWidget {
  final int id;
  final String contenido;
  final String futbolista;
  final String foto;

  const BlogRow({
    Key? key,
    required this.id,
    required this.contenido,
    required this.futbolista,
    required this.foto,
  }) : super(key: key);

  @override
  _BlogRowState createState() => _BlogRowState();
}

class _BlogRowState extends State<BlogRow> {
  String selectedReaction = 'like'; // Default reaction

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mostrar Foto del Tweet si está disponible
                if (widget.foto.isNotEmpty)
                  Image.network(
                    widget.foto,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 10),

                // Mostrar nombre del futbolista
                Text(
                  'Futbolista: ${widget.futbolista}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),

                // Mostrar contenido del tweet
                Text(
                  'Contenido: ${widget.contenido}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 10),

                // Selección de tipo de reacción
                DropdownButton<String>(
                  value: selectedReaction,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedReaction = newValue!;
                    });
                  },
                  items: <String>['like', 'love', 'angry', 'sad', 'goat']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.toUpperCase()),
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: 10),

                // Mutación para crear una reacción (like, love, etc.)
                Mutation(
                  options: MutationOptions(
                    document: gql(createReactionMutation),
                    update: (cache, result) => cache,
                    onCompleted: (result) {
                      if (result == null) {
                        print('Completed with errors');
                      } else {
                        print('${widget.id} reaccionado con $selectedReaction');
                        print(result);
                      }
                    },
                    onError: (error) {
                      print('Error:');
                      print(error?.graphqlErrors[0].message);
                    },
                  ),
                  builder: (runMutation, result) {
                    return ElevatedButton(
                      onPressed: () {
                        runMutation({
                          "tweetId": widget.id,
                          "reactionType": selectedReaction,
                        });
                      },
                      child: const Text('Reaccionar'),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'MyAppState.dart';
import 'package:url_launcher/url_launcher.dart';

// GraphQL Queries
const String query = """
query Tweets {
  tweets {
    id
    contenido
    futbolista
    createAt
    reactionCount
    comments {
      id
      text
      createdAt
      user {
        username
      }
    }
    reactions {
      id
      reactionType
    }
    foto
    postedBy {
      username
    }
  }
}
""";

const String createCommentMutation = """
mutation CreateComment(\$tweetId: Int!, \$text: String!) {
  createComment(tweetId: \$tweetId, text: \$text) {
    comment {
      id
      text
      createdAt
      user {
        username
      }
    }
  }
}
""";

const String createReactionMutation = """
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

const String deleteReactionMutation = """
mutation DeleteReaction(\$reactionId: Int!) {
  deleteReaction(
    reactionId: \$reactionId
  ) {
    success
  }
}
""";

const String deleteTweetMutation = """
mutation DeleteTweet(\$tweetId: Int!) {
  deleteTweet(tweetId: \$tweetId) {
    success
  }
}
""";

Future<void> abrirEnlace(BuildContext context, String url) async {
  final fixedUrl = url.startsWith('http') ? url : 'https://$url';
  final uri = Uri.parse(fixedUrl);

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('🌐 Intentando abrir: $fixedUrl')));

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      final msg =
          '❌ No se pudo abrir el enlace: $fixedUrl (launchUrl retornó false)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      print(msg);
    }
  } catch (e) {
    final msg = '❌ Error al abrir enlace: $e';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    print(msg);
  }
}

class LogsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.token.isEmpty) {
      return const Center(child: Text('No login yet.'));
    }

    return Query(
      options: QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (result.hasException) {
          return Center(child: Text('Error: ${result.exception.toString()}'));
        }

        final tweets = result.data?['tweets'] ?? [];

        if (tweets.isEmpty) {
          return const Center(child: Text("No tweets found!"));
        }

        return ListView.builder(
          itemCount: tweets.length,
          itemBuilder: (context, index) {
            final tweet = tweets[index];
            final id = int.parse(tweet['id'].toString());
            final contenido = tweet['contenido'] ?? '';
            final futbolista = tweet['futbolista'] ?? '';
            final reactionCount = tweet['reactionCount'] ?? 0;
            final comments = (tweet['comments'] as List<dynamic>? ?? []);
            final reactions = (tweet['reactions'] as List<dynamic>? ?? []);
            final foto = tweet['foto'] ?? '';
            final postedBy = tweet['postedBy']['username'] ?? 'Desconocido';
            final createAt = tweet['createAt'] ?? '';

            String commentsText = comments.isEmpty
                ? "No hay comentarios aún."
                : comments
                      .map((c) {
                        final username = c['user']?['username'] ?? 'Anon';
                        final text = c['text'] ?? '';
                        return '- $username: $text';
                      })
                      .join('\n');

            // Obtener tipo y cantidad de reacciones
            String reactionsText = reactions.isEmpty
                ? "No hay reacciones aún."
                : reactions
                      .map((r) {
                        final reactionType = r['reactionType'] ?? 'Unknown';
                        return '$reactionType';
                      })
                      .join(', ');

            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Autor y fecha
                    Row(
                      children: [
                        Text(
                          postedBy,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          createAt,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Foto
                    if (foto.isNotEmpty)
                      Image.network(
                        foto,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 8),

                    // Futbolista y contenido
                    Text(
                      futbolista,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      contenido,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Reacciones actuales
                    Text(
                      "Reacciones: $reactionsText",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),

                    // Botones para reacciones
                    ReactionForm(
                      tweetId: id,
                      reactions: reactions,
                      onReactionChanged: () {
                        refetch?.call();
                      },
                    ),

                    // Botón para eliminar tweet
                    /*Mutation(
                      options: MutationOptions(
                        document: gql(deleteTweetMutation),
                        onCompleted: (_) {
                          refetch?.call(); // Vuelve a cargar los tweets
                        },
                        onError: (error) {
                          print(
                            'Error al eliminar el tweet: ${error?.graphqlErrors[0].message}',
                          );
                        },
                      ),
                      builder: (runMutation, result) {
                        return ElevatedButton.icon(
                          onPressed: () {
                            runMutation({"tweetId": id});
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text("Eliminar Tweet"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),*/

                    // Comentarios
                    const Text(
                      "Comentarios:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(commentsText, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),

                    // Formulario de comentarios
                    CommentForm(
                      tweetId: id,
                      onCommentAdded: () {
                        refetch?.call();
                      },
                    ),

                    // Botón para eliminar tweet
                    Mutation(
                      options: MutationOptions(
                        document: gql(deleteTweetMutation),
                        onCompleted: (_) {
                          refetch?.call(); // Vuelve a cargar los tweets
                        },
                        onError: (error) {
                          print(
                            'Error al eliminar el tweet: ${error?.graphqlErrors[0].message}',
                          );
                        },
                      ),
                      builder: (runMutation, result) {
                        return ElevatedButton.icon(
                          onPressed: () {
                            runMutation({"tweetId": id});
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text("Eliminar Tweet"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CommentForm extends StatefulWidget {
  final int tweetId;
  final VoidCallback onCommentAdded;

  CommentForm({required this.tweetId, required this.onCommentAdded});

  @override
  _CommentFormState createState() => _CommentFormState();
}

class _CommentFormState extends State<CommentForm> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: gql(createCommentMutation),
        onCompleted: (_) {
          _controller.clear();
          widget.onCommentAdded();
        },
      ),
      builder: (RunMutation runMutation, QueryResult? result) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Nuevo comentario",
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) {
                    runMutation({"tweetId": widget.tweetId, "text": text});
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text("Comentar"),
              ),
            ),
            if (result?.hasException ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  result!.exception.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }
}

class ReactionForm extends StatefulWidget {
  final int tweetId;
  final List<dynamic> reactions;
  final VoidCallback onReactionChanged;

  const ReactionForm({
    required this.tweetId,
    required this.reactions,
    required this.onReactionChanged,
  });

  @override
  _ReactionFormState createState() => _ReactionFormState();
}

class _ReactionFormState extends State<ReactionForm> {
  String selectedReaction = 'like';
  int? myReactionId;

  @override
  void initState() {
    super.initState();

    final appState = context.read<MyAppState>();
    final myReaction = widget.reactions.firstWhere(
      (r) => r['user']?['username'] == appState.username,
      orElse: () => null,
    );

    if (myReaction != null) {
      myReactionId = int.tryParse(myReaction['id'].toString());
      selectedReaction = myReaction['reactionType'] ?? 'like';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: selectedReaction,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedReaction = newValue;
              });
            }
          },
          items: <String>['like', 'love', 'angry', 'sad', 'goat']
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value.toUpperCase()),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (myReactionId != null)
              Mutation(
                options: MutationOptions(
                  document: gql(deleteReactionMutation),
                  onCompleted: (_) {
                    widget.onReactionChanged();
                  },
                ),
                builder: (runMutation, result) {
                  return ElevatedButton.icon(
                    onPressed: () {
                      runMutation({"reactionId": myReactionId});
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text("Eliminar reacción"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            const SizedBox(width: 8),
            Mutation(
              options: MutationOptions(
                document: gql(createReactionMutation),
                onCompleted: (_) {
                  widget.onReactionChanged();
                },
              ),
              builder: (runMutation, result) {
                return ElevatedButton.icon(
                  onPressed: () {
                    if (myReactionId != null &&
                        selectedReaction ==
                            widget.reactions.firstWhere(
                              (r) =>
                                  r['id'].toString() == myReactionId.toString(),
                              orElse: () => {},
                            )['reactionType']) {
                      runMutation({"reactionId": myReactionId});
                    } else {
                      runMutation({
                        "tweetId": widget.tweetId,
                        "reactionType": selectedReaction,
                      });
                    }
                  },
                  icon: const Icon(Icons.thumb_up),
                  label: const Text("Reaccionar"),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

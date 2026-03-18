import 'package:flutter/material.dart';
import 'create_muscle_screen.dart';

class ItemManagementScreen<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) labelBuilder;

  const ItemManagementScreen({
    super.key,
    required this.title,
    required this.items,
    required this.labelBuilder,
  });

  @override
  State<ItemManagementScreen<T>> createState() => _ItemManagementScreenState<T>();
}

class _ItemManagementScreenState<T> extends State<ItemManagementScreen<T>> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        itemCount: widget.items.length + 1, // +1 for the button
        itemBuilder: (context, index) {
          if (index == widget.items.length) {
            // This is the last item, show the button
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (widget.title == 'My Muscles') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateMuscleScreen()),
                    );
                    if (result != null && result is T) {
                      setState(() {
                        widget.items.add(result);
                      });
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('create new'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            );
          }

          // Show the muscle item
          return ListTile(
            title: Text(widget.labelBuilder(widget.items[index])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {},
                  tooltip: 'Show',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      widget.items.removeAt(index);
                    });
                  },
                  tooltip: 'Delete',
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () {},
                  tooltip: 'Copy',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

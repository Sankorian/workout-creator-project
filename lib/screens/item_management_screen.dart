import 'package:flutter/material.dart';

class ItemManagementScreen<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(labelBuilder(items[index])),
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
                        onPressed: () {},
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
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('create new'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

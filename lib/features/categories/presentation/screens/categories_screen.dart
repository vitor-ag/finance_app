import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';
import '../widgets/category_card.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = _tabController.index == 0 ? 'expense' : 'income';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nova Categoria',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Categoria (ex: Alimentação)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Despesa')),
                    ButtonSegment(value: 'income', label: Text('Receita')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (selection) =>
                      setState(() => selectedType = selection.first),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      final newCategory = Category(
                        name: name,
                        type: selectedType,
                      );

                      await ref
                          .read(categoryRepositoryProvider)
                          .createCategory(newCategory);

                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Salvar Categoria'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(WidgetRef ref, String type) {
    final categoriesAsync = ref.watch(allCategoriesProvider(type: type));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erro: $error')),
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nenhuma categoria cadastrada',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CategoryCard(category: categories[index]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categorias',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Despesas'),
            Tab(text: 'Receitas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(ref, 'expense'),
          _buildList(ref, 'income'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria'),
      ),
    );
  }
}
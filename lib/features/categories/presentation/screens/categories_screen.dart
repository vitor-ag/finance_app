import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/record_actions.dart';
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

  Future<void> _showCategoryForm({Category? category}) async {
    final form = GlobalKey<FormState>();
    var name = category?.name ?? '';
    var selectedType =
        category?.type ?? (_tabController.index == 0 ? 'expense' : 'income');
    var parentId = category?.parentId;
    var saving = false;
    final repo = ref.read(categoryRepositoryProvider);
    final categories = [
      ...?ref.read(allCategoriesProvider(type: 'expense')).valueOrNull,
      ...?ref.read(allCategoriesProvider(type: 'income')).valueOrNull,
    ];
    final hasChildren =
        category != null &&
        categories.any((item) => item.parentId == category.id);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final parents = categories.where(
            (item) =>
                item.type == selectedType &&
                item.id != category?.id &&
                (item.id == parentId ||
                    (item.isActive && item.parentId == null)),
          );
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category == null ? 'Nova Categoria' : 'Editar Categoria',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: name,
                      onSaved: (value) => name = value!.trim(),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty || text.length > 60) {
                          return 'Digite um nome de 1 a 60 caracteres.';
                        }
                        return null;
                      },
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
                      onSelectionChanged: category != null
                          ? null
                          : (selection) => setState(() {
                              selectedType = selection.first;
                              parentId = null;
                            }),
                    ),
                    if (!hasChildren) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        key: ValueKey(selectedType),
                        initialValue: parents.any((item) => item.id == parentId)
                            ? parentId
                            : null,
                        isExpanded: true,
                        hint: const Text('Sem categoria pai'),
                        decoration: const InputDecoration(
                          labelText: 'Categoria pai',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            child: Text('Sem categoria pai'),
                          ),
                          for (final item in parents)
                            DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                        ],
                        onChanged: (value) => setState(() => parentId = value),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final state = form.currentState!;
                                if (!state.validate()) return;
                                state.save();
                                setState(() => saving = true);
                                final edited = Category(
                                  id: category?.id,
                                  name: name,
                                  type: selectedType,
                                  parentId: parentId,
                                  color: category?.color,
                                  icon: category?.icon,
                                );
                                try {
                                  if (category == null) {
                                    await repo.createCategory(edited);
                                  } else {
                                    await repo.updateCategory(edited);
                                  }
                                  if (context.mounted) Navigator.pop(context);
                                } catch (error) {
                                  if (!context.mounted) return;
                                  setState(() => saving = false);
                                  showRecordError(
                                    context,
                                    error,
                                    'Não foi possível salvar a categoria.',
                                  );
                                }
                              },
                        child: const Text('Salvar Categoria'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _archiveCategory(Category category) async {
    final repo = ref.read(categoryRepositoryProvider);
    final confirmed = await confirmRecordAction(
      context,
      title: 'Arquivar categoria?',
      message:
          '${category.name} sairá das opções de novos lançamentos. O histórico será preservado.',
      action: 'Arquivar',
    );
    if (!confirmed || !mounted) return;
    try {
      await repo.archiveCategory(category.id!);
    } catch (error) {
      if (mounted) {
        showRecordError(
          context,
          error,
          'Não foi possível arquivar a categoria.',
        );
      }
    }
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

        final names = {
          for (final category in categories) category.id: category.name,
        };
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CategoryCard(
              category: categories[index],
              parentName: names[categories[index].parentId],
              onTap: () => _showCategoryForm(category: categories[index]),
              onArchive: categories[index].isActive
                  ? () => _archiveCategory(categories[index])
                  : null,
            ),
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
        children: [_buildList(ref, 'expense'), _buildList(ref, 'income')],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCategoryForm,
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria'),
      ),
    );
  }
}

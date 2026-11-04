import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/list_item.dart';
import 'category_style.dart';

/// Bottom sheet for a new item. Pops with a [NewItem], or null.
class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key, required this.listId, this.initialName = ''});

  final String listId;
  final String initialName;

  static Future<NewItem?> show(BuildContext context, {required String listId, String initialName = ''}) {
    return showModalBottomSheet<NewItem>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => AddItemSheet(listId: listId, initialName: initialName),
    );
  }

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  final _price = TextEditingController();
  late ItemCategory _category = ItemCategory.guess(widget.initialName);
  bool _pickedCategory = false;
  int _quantity = 1;
  String _unit = 'pcs';

  static const _units = ['pcs', 'kg', 'g', 'L', 'pack', 'bottle'];

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(NewItem(
      listId: widget.listId,
      name: _name.text,
      category: _category,
      quantity: _quantity,
      unit: _unit,
      price: double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add an item', style: text.headlineMedium?.copyWith(fontSize: 24)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: widget.initialName.isEmpty,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Oat milk, lemons, bin bags...'),
              onChanged: (value) {
                // Keep guessing until the user picks a category themselves.
                if (!_pickedCategory) setState(() => _category = ItemCategory.guess(value));
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            Text('Category', style: text.titleSmall),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final category in ItemCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        category: category,
                        selected: category == _category,
                        onTap: () => setState(() {
                          _category = category;
                          _pickedCategory = true;
                        }),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text('Quantity', style: text.titleSmall),
                const Spacer(),
                _StepButton(
                  icon: Icons.remove_rounded,
                  onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                ),
                SizedBox(
                  width: 44,
                  child: Text('$_quantity', textAlign: TextAlign.center, style: text.titleLarge),
                ),
                _StepButton(icon: Icons.add_rounded, onTap: () => setState(() => _quantity++)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final unit in _units)
                  ChoiceChip(
                    label: Text(unit),
                    selected: unit == _unit,
                    onSelected: (_) => setState(() => _unit = unit),
                    showCheckmark: false,
                    shape: const StadiumBorder(),
                    side: BorderSide(color: unit == _unit ? c.primary : c.border),
                    backgroundColor: c.card,
                    selectedColor: c.primarySoft,
                    labelStyle: text.labelMedium?.copyWith(
                      color: unit == _unit ? c.primary : c.ink,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Price per unit (optional)',
                prefixText: '€ ',
              ),
            ),
            const SizedBox(height: 22),
            ListenableBuilder(
              listenable: _name,
              builder: (context, _) => PillButton(
                label: 'Add to list',
                icon: Icons.add_rounded,
                onPressed: _name.text.trim().isEmpty ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.selected, required this.onTap});

  final ItemCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = CategoryStyle.of(context, category);
    return Material(
      color: selected ? style.tile : c.card,
      shape: StadiumBorder(side: BorderSide(color: selected ? style.ink : c.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(style.icon, size: 16, color: style.ink),
              const SizedBox(width: 6),
              Text(category.label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primarySoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: onTap == null ? c.muted : c.primary),
        ),
      ),
    );
  }
}

/// Bottom sheet for a new list. Pops with (name, store), or null.
class NewListSheet extends StatefulWidget {
  const NewListSheet({super.key});

  static Future<(String, String)?> show(BuildContext context) {
    return showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const NewListSheet(),
    );
  }

  @override
  State<NewListSheet> createState() => _NewListSheetState();
}

class _NewListSheetState extends State<NewListSheet> {
  final _name = TextEditingController();
  final _store = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _store.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop((_name.text, _store.text));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('New list', style: text.headlineMedium?.copyWith(fontSize: 24)),
          const SizedBox(height: 6),
          Text('You can invite people to it afterwards.', style: text.bodyMedium?.copyWith(color: context.colors.muted)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Name, e.g. Weekly groceries'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _store,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Store (optional)'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 22),
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) => PillButton(
              label: 'Create list',
              icon: Icons.check_rounded,
              onPressed: _name.text.trim().isEmpty ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}

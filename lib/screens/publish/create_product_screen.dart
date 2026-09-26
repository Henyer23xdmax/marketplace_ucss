import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/theme_constants.dart';
import '../../models/category.dart';
import '../../providers/catalog_provider.dart';

class CreateProductScreen extends ConsumerStatefulWidget {
  const CreateProductScreen({super.key});

  @override
  ConsumerState<CreateProductScreen> createState() =>
      _CreateProductScreenState();
}

class _CreateProductScreenState extends ConsumerState<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');

  String? _selectedCategoryId;
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> picked = await _picker.pickMultiImage(
          imageQuality: 80,
        );
        if (picked.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(picked);
          });
        }
      } else {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (photo != null) {
          setState(() {
            _selectedImages.add(photo);
          });
        }
      }
    } catch (e) {
      _showSnack('Error al seleccionar imagen: $e', isError: true);
    }
  }

  Future<void> _submitProduct() async {
    if (_isUploading) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      _showSnack('Por favor selecciona una categoría', isError: true);
      return;
    }

    if (_selectedImages.isEmpty) {
      _showSnack(
        'Adjunta al menos una foto de tu producto para mayor confianza',
        isError: true,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final price = double.tryParse(_priceCtrl.text) ?? 0.0;
      final stock = int.tryParse(_stockCtrl.text) ?? 1;

      await ref
          .read(productCreationProvider.notifier)
          .createProduct(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            price: price,
            stock: stock,
            categoryId: _selectedCategoryId!,
            imageFiles: _selectedImages,
          );

      // Refrescar el feed
      ref.invalidate(productsProvider);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          'Error al publicar: ${e.toString().replaceAll("Exception: ", "")}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('¡Artículo Publicado!'),
        content: const Text(
          'Tu producto ya está visible para la comunidad estudiantil de la UCSS.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Aceptar'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetForm();
            },
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    _stockCtrl.text = '1';
    setState(() {
      _selectedCategoryId = null;
      _selectedImages.clear();
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Vender en UCSS')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de Fotos (Storage)
              Text(
                'Fotos del Artículo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sube fotos nítidas para que tus compañeros vean el estado real.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Botón para agregar fotos
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _showImageSourcePicker(context),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.6) : AppColors.primary.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.camera_fill,
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Añadir Foto',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Lista de fotos seleccionadas
                    ..._selectedImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final image = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.border,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: kIsWeb
                                  ? Image.network(image.path, fit: BoxFit.cover)
                                  : Image.file(
                                      File(image.path),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 14,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppColors.shadow.withValues(alpha: 0.54),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.xmark,
                                  size: 14,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tarjeta de Datos del Producto
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Título del Artículo *',
                        hintText: 'Ej. Libro Anatomía Humana Netter 7ma Ed.',
                        fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ingresa el título del artículo'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Selector de Categoría
                    categoriesAsync.when(
                      data: (cats) {
                        if (cats.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warningContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: AppColors.warning,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'No hay categorías en la base de datos',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: const Text('Recargar', style: TextStyle(fontSize: 12)),
                                  onPressed: () => ref.refresh(categoriesProvider),
                                ),
                              ],
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
                          hint: Text(
                            'Selecciona una categoría académica',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Categoría Académica *',
                            fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                          ),
                          items: cats.map((Category c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Row(
                                children: [
                                  Icon(
                                    c.cupertinoIcon,
                                    size: 18,
                                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkText : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategoryId = val),
                          validator: (val) => val == null
                              ? 'Por favor selecciona una categoría'
                              : null,
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CupertinoActivityIndicator(),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.clear_circled, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Error al cargar categorías: $err',
                                style: const TextStyle(fontSize: 12, color: AppColors.error),
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
                              onPressed: () => ref.refresh(categoriesProvider),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Precio (S/.) *',
                              hintText: '0.00',
                              prefixText: 'S/ ',
                              fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Ingresa el precio';
                              if (double.tryParse(v) == null)
                                return 'Precio inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Stock Disponible *',
                              hintText: '1',
                              fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Ingresa el stock';
                              if (int.tryParse(v) == null)
                                return 'Número inválido';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Descripción y Detalles *',
                        hintText: 'Indica el ciclo, carrera, estado de conservación y cualquier detalle importante...',
                        fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa una descripción del artículo';
                        }
                        if (v.trim().length < 10) {
                          return 'La descripción debe tener al menos 10 caracteres';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botón Publicar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                    foregroundColor: isDark ? AppColors.darkBackground : AppColors.onPrimary,
                  ),
                  onPressed: _isUploading ? null : _submitProduct,
                  child: _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(
                              color: isDark ? AppColors.darkBackground : AppColors.onPrimary,
                            ),
                            const SizedBox(width: 10),
                            const Text('Subiendo fotos a Supabase Storage...'),
                          ],
                        )
                      : const Text(
                          'Publicar en UCSS Market',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourcePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Agregar Foto del Producto'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Tomar Foto con Cámara'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickImage(ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Elegir de Galería de Fotos'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }
}

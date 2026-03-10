import 'anime_item_dto.dart';

/// Resposta paginada por cursor retornada por endpoints de filtro e busca.
///
/// Estrutura comum a `FilterAnimeResponseDto` e `SearchAnimeResponseDto`
/// no backend.
class PaginatedAnimeResponseDto {
  const PaginatedAnimeResponseDto({
    required this.items,
    this.nextCursor,
  });

  factory PaginatedAnimeResponseDto.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => AnimeItemDto.fromJson(e as Map<String, dynamic>))
            .toList(growable: false) ??
        const [];
    return PaginatedAnimeResponseDto(
      items: itemsList,
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<AnimeItemDto> items;

  /// Cursor opaco para a próxima página. `null` se não há mais dados.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}

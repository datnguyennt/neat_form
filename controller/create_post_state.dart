import 'package:beauty_mobile_app/core/exceptions/app_exception.dart';
import 'package:beauty_mobile_app/core/forms/common_form_field_state.dart';
import 'package:beauty_mobile_app/core/forms/submission_status.dart';
import 'package:beauty_mobile_app/core/network/schema.graphql.dart';
import 'package:beauty_mobile_app/features/main/data/models/home_post_model.dart';
import 'package:beauty_mobile_app/features/main/data/models/local_post_model.dart';
import 'package:beauty_mobile_app/features/post/data/models/category_model.dart';
import 'package:beauty_mobile_app/features/post/data/models/topic_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_post_state.freezed.dart';

enum CreatePostField {
  title,
  description,
}

@freezed
abstract class CreatePostState with _$CreatePostState {
  const CreatePostState._();
  const factory CreatePostState({
    @Default({}) Map<CreatePostField, CommonFormFieldState<dynamic>> fields,
    @Default([]) List<LocalPostMedia> mediaBeforeItems,
    @Default([]) List<LocalPostMedia> mediaAfterItems,
    // For non-before-after topics (STANDARD / REEL)
    @Default([]) List<LocalPostMedia> mediaItems,
    @Default([]) List<String> tags,
    @Default(SubmissionStatus.idle) SubmissionStatus status,
    @Default(false) bool isDraftSaved,
    @Default(false) bool isLoadingPost,

    /// Error từ lần submit gần nhất (chỉ dùng cho logging/UI dispatch)
    AppException? submitError,
    TopicModel? topic,
    CategoryModel? majorCategory,
    CategoryModel? minorCategory,
    String? editPostId,
    Enum$PostStatus? editPostStatus,
    PostModel? originalPost,
  }) = _CreatePostState;

  bool get isSubmitting => status == SubmissionStatus.submitting;
  bool get isSuccess => status == SubmissionStatus.success;
  bool get isFailure => status == SubmissionStatus.failure;
  bool get isEditMode => editPostId != null;
  bool get isEditingDraft => editPostStatus == Enum$PostStatus.DRAFT;

  // Topic type helpers
  bool get isBeforeAfterTopic => topic?.isBeforeAfter == true;
  bool get isReelTopic => topic?.isReel == true;
  bool get isQnaTopic => topic?.isQnA == true;

  // Media galleries
  MediaGallery get beforeGallery => MediaGallery(mediaBeforeItems);
  MediaGallery get afterGallery => MediaGallery(mediaAfterItems);
  MediaGallery get standardGallery => MediaGallery(mediaItems);

  // Before/After media
  bool get hasBeforeMedia => mediaBeforeItems.isNotEmpty;
  bool get hasAfterMedia => mediaAfterItems.isNotEmpty;
  bool get hasBeforeMediaCover => beforeGallery.hasCover;
  bool get hasAfterMediaCover => afterGallery.hasCover;
  bool get hasBeforeAndAfterMedia => hasBeforeMedia && hasAfterMedia;

  // Standard/Reel media
  bool get hasMediaItems => mediaItems.isNotEmpty;
  bool get hasMediaItemsCover => standardGallery.hasCover;


  bool get titleValid => fields.isFilledAndValid(CreatePostField.title);
  bool get descriptionValid =>
      fields.isFilledAndValid(CreatePostField.description);

  // Description is optional for non-QNA: empty is fine, non-empty must be valid.
  bool get _isDescriptionOptionallyValid {
    final field = fields[CreatePostField.description];
    return field == null || field.isEmpty || field.isValid;
  }

  bool get isInputDetailsValid {
    // QNA: only description (content) is required; title is hidden.
    if (isQnaTopic) return descriptionValid;
    // All other topics: title required, description optional.
    return titleValid && _isDescriptionOptionallyValid;
  }

  bool get hasTopicAndCategory {
    final hasTopic = topic?.id.isNotEmpty ?? false;
    // SmallTalk posts have no category — only a topic is required.
    if (topic?.isSmallTalk ?? false) return hasTopic;
    return hasTopic && (majorCategory?.id.isNotEmpty ?? false);
  }

  bool get canSubmit {
    if (!hasTopicAndCategory || isSubmitting || !isInputDetailsValid) {
      return false;
    }
    if (isBeforeAfterTopic) return hasBeforeMediaCover && hasAfterMediaCover;
    if (isReelTopic) return hasMediaItems;

    // Standard topics (QNA, REVIEW, SMALL_TALK, EXPERT_INSIGHTS) do not require media
    return true;
  }

  bool get canSaveDraft {
    return canSubmit;
  }

  /// Input section tự động hiện khi có đủ ảnh before + after (before-after)
  /// hoặc luôn hiện với các topic khác
  bool get showInputSection => !isBeforeAfterTopic || hasBeforeAndAfterMedia;

  bool get hasUnsavedChanges =>
      mediaBeforeItems.isNotEmpty ||
      mediaAfterItems.isNotEmpty ||
      mediaItems.isNotEmpty ||
      (fields[CreatePostField.title]?.value as String?)?.isNotEmpty == true ||
      (fields[CreatePostField.description]?.value as String?)?.isNotEmpty == true;

  bool get hasPostChanged {
    if (originalPost == null) {
      return hasUnsavedChanges;
    }

    final originalTitle = originalPost!.title ?? '';
    final currentTitle =
        (fields[CreatePostField.title]?.value as String?) ?? '';
    if (originalTitle != currentTitle) return true;

    final originalDescription = originalPost!.description ?? '';
    final currentDescription =
        (fields[CreatePostField.description]?.value as String?) ?? '';
    if (originalDescription != currentDescription) return true;

    if (originalPost!.postTopic?.id != topic?.id) return true;

    if (originalPost!.category?.major?.id != majorCategory?.id) return true;
    if (originalPost!.category?.minor?.id != minorCategory?.id) return true;

    final originalTags = originalPost!.tags;
    if (originalTags.length != tags.length) return true;
    if (!const DeepCollectionEquality.unordered().equals(originalTags, tags)) {
      return true;
    }

    final currentBefore = mediaBeforeItems;
    final currentAfter = mediaAfterItems;
    final currentStandard = mediaItems;

    final originalBefore = originalPost!.mediaItems
        .where((m) => m.role == Enum$PostMediaRole.BEFORE)
        .toList();
    final originalAfter = originalPost!.mediaItems
        .where((m) => m.role == Enum$PostMediaRole.AFTER)
        .toList();
    final originalStandard = originalPost!.mediaItems
        .where(
          (m) =>
              m.role != Enum$PostMediaRole.BEFORE &&
              m.role != Enum$PostMediaRole.AFTER,
        )
        .toList();

    if (currentBefore.length != originalBefore.length) return true;
    if (currentAfter.length != originalAfter.length) return true;
    if (currentStandard.length != originalStandard.length) return true;

    for (var i = 0; i < currentBefore.length; i++) {
      final cur = currentBefore[i];
      final orig = originalBefore[i];
      if (cur.uploadedMediaId != orig.mediaId) return true;
      if (cur.isCover != orig.isCover) return true;
    }
    for (var i = 0; i < currentAfter.length; i++) {
      final cur = currentAfter[i];
      final orig = originalAfter[i];
      if (cur.uploadedMediaId != orig.mediaId) return true;
      if (cur.isCover != orig.isCover) return true;
    }
    for (var i = 0; i < currentStandard.length; i++) {
      final cur = currentStandard[i];
      final orig = originalStandard[i];
      if (cur.uploadedMediaId != orig.mediaId) return true;
      if (cur.isCover != orig.isCover) return true;
    }

    return false;
  }
}

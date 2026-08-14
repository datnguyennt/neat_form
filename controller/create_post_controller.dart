import 'dart:io';

import 'package:beauty_mobile_app/core/common_providers/submission_mixin.dart';
import 'package:beauty_mobile_app/core/constants/constants.dart';
import 'package:beauty_mobile_app/core/constants/error_constants.dart';
import 'package:beauty_mobile_app/core/exceptions/app_exception.dart';
import 'package:beauty_mobile_app/core/forms/app_validators.dart';
import 'package:beauty_mobile_app/core/forms/common_form_field_state.dart';
import 'package:beauty_mobile_app/core/forms/form_mixin.dart';
import 'package:beauty_mobile_app/core/forms/submission_status.dart';
import 'package:beauty_mobile_app/core/network/result.dart';
import 'package:beauty_mobile_app/core/network/schema.graphql.dart';
import 'package:beauty_mobile_app/core/providers/post_cache_provider.dart';
import 'package:beauty_mobile_app/core/service/background_post_service.dart';
import 'package:beauty_mobile_app/core/service/media_cleanup_service.dart';
import 'package:beauty_mobile_app/core/service/media_upload_service.dart';
import 'package:beauty_mobile_app/core/utils/file_util.dart';
import 'package:beauty_mobile_app/core/utils/logger_util.dart';
import 'package:beauty_mobile_app/features/main/data/models/home_post_model.dart';
import 'package:beauty_mobile_app/features/main/data/models/local_post_model.dart';
import 'package:beauty_mobile_app/features/main/presentation/controllers/home_bootstrap/home_bootstrap_controller.dart';
import 'package:beauty_mobile_app/features/master_data/data/repository/master_data_repository.dart';
import 'package:beauty_mobile_app/features/master_data/presentation/providers/master_data_controller.dart';
import 'package:beauty_mobile_app/features/post/data/models/category_model.dart';
import 'package:beauty_mobile_app/features/post/data/models/local_media_item.dart'
    as hive_model;
import 'package:beauty_mobile_app/features/post/data/models/post_task.dart';
import 'package:beauty_mobile_app/features/post/data/models/topic_model.dart';
import 'package:beauty_mobile_app/features/post/data/repository/post_repository.dart';
import 'package:beauty_mobile_app/features/post/presentation/create_post/controller/create_post_state.dart';
import 'package:beauty_mobile_app/features/post/presentation/post_list/controller/post_list_controller.dart';
import 'package:beauty_mobile_app/features/user/presentation/my_post/controller/draft_posts_tab_controller.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'create_post_controller.g.dart';

@riverpod
class CreatePostController extends _$CreatePostController
    with FormMixin<CreatePostField>, SubmissionMixin<CreatePostState> {
  final Set<String> _temporaryFilePaths = {};
  bool _shouldKeepFiles = false;

  @override
  CreatePostState build() {
    ref.onDispose(() {
      if (_shouldKeepFiles) {
        // Did submit successfully, BackgroundService owns the files now
        return;
      }

      // We didn't submit successfully. Clean up media from local caches.
      for (final path in _temporaryFilePaths) {
        MediaCleanupService.deleteFileSync(path);
      }
    });

    return const CreatePostState(
      fields: {
        CreatePostField.title: CommonFormFieldState<String?>(
          value: null,
        ),
        CreatePostField.description: CommonFormFieldState<String?>(
          value: null,
        ),
      },
    );
  }

  @override
  Map<CreatePostField, CommonFormFieldState> get fields => state.fields;

  @override
  void updateStateWithFields(
    Map<CreatePostField, CommonFormFieldState> newFields,
  ) {
    state = state.copyWith(fields: newFields);
  }

  @override
  Map<CreatePostField, Validator<dynamic>> get validators {
    // QNA: title is hidden — only description (content) is required.
    if (state.isQnaTopic) {
      return {
        CreatePostField.description: AppValidators.combine([
          AppValidators.required,
          AppValidators.minLength(5),
          AppValidators.maxLength(2000),
        ]),
      };
    }
    // All other topics: title required, description optional (no required validator).
    return {
      CreatePostField.title: AppValidators.combine([
        AppValidators.required,
        AppValidators.minLength(5),
        AppValidators.maxLength(60),
      ]),
      CreatePostField.description: AppValidators.combine([
        AppValidators.minLength(5),
        AppValidators.maxLength(2000),
      ]),
    };
  }

  void setAndValidateTitle(String? title) {
    final validator = validators[CreatePostField.title];
    if (validator == null) return;
    setAndValidateField(CreatePostField.title, title, validator);
  }

  void setAndValidateDescription(String? desc) {
    setAndValidateField(
      CreatePostField.description,
      desc,
      validators[CreatePostField.description]!,
    );
  }

  void updateMediaList(
    List<LocalPostMedia> mediaList, {
    required bool isBefore,
  }) {
    for (final media in mediaList) {
      _temporaryFilePaths.add(media.localPath);
    }

    if (isBefore) {
      state = state.copyWith(mediaBeforeItems: mediaList);
    } else {
      state = state.copyWith(mediaAfterItems: mediaList);
    }
  }

  void removeMedia(int index, {required bool isBefore}) {
    if (isBefore) {
      final items = <LocalPostMedia>[...state.mediaBeforeItems];
      final removed = items.removeAt(index);

      if (removed.isCover && items.isNotEmpty) {
        items[0] = items[0].copyWith(isCover: true);
      }

      state = state.copyWith(mediaBeforeItems: items);
    } else {
      final items = <LocalPostMedia>[...state.mediaAfterItems];
      final removed = items.removeAt(index);

      if (removed.isCover && items.isNotEmpty) {
        items[0] = items[0].copyWith(isCover: true);
      }

      state = state.copyWith(mediaAfterItems: items);
    }
  }

  void updateMediaOrder(int oldIndex, int newIndex, {required bool isBefore}) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (isBefore) {
      final items = <LocalPostMedia>[...state.mediaBeforeItems];
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      state = state.copyWith(mediaBeforeItems: items);
    } else {
      final items = <LocalPostMedia>[...state.mediaAfterItems];
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      state = state.copyWith(mediaAfterItems: items);
    }
  }

  void markAsCover(int index, {required bool isBefore}) {
    if (isBefore) {
      final items = state.mediaBeforeItems
          .map((e) => e.copyWith(isCover: false))
          .toList();
      items[index] = items[index].copyWith(isCover: true);
      state = state.copyWith(mediaBeforeItems: items);
    } else {
      final items = state.mediaAfterItems
          .map((e) => e.copyWith(isCover: false))
          .toList();
      items[index] = items[index].copyWith(isCover: true);
      state = state.copyWith(mediaAfterItems: items);
    }
  }

  void updateMedia(
    int index,
    LocalPostMedia updatedMedia, {
    required bool isBefore,
  }) {
    if (isBefore) {
      final items = <LocalPostMedia>[...state.mediaBeforeItems];
      items[index] = updatedMedia;
      state = state.copyWith(mediaBeforeItems: items);
    } else {
      final items = <LocalPostMedia>[...state.mediaAfterItems];
      items[index] = updatedMedia;
      state = state.copyWith(mediaAfterItems: items);
    }
  }

  void updateTags(List<String> tags) {
    state = state.copyWith(tags: tags);
  }

  // --- Standard / Reel media ---

  void updateStandardMediaList(List<LocalPostMedia> mediaList) {
    for (final media in mediaList) {
      _temporaryFilePaths.add(media.localPath);
    }
    state = state.copyWith(mediaItems: mediaList);
  }

  void removeStandardMedia(int index) {
    final items = <LocalPostMedia>[...state.mediaItems];
    final removed = items.removeAt(index);
    if (removed.isCover && items.isNotEmpty) {
      items[0] = items[0].copyWith(isCover: true);
    }
    state = state.copyWith(mediaItems: items);
  }

  void updateStandardMedia(int index, LocalPostMedia updatedMedia) {
    final items = <LocalPostMedia>[...state.mediaItems];
    items[index] = updatedMedia;
    state = state.copyWith(mediaItems: items);
  }

  void markStandardAsCover(int index) {
    final items = state.mediaItems
        .map((e) => e.copyWith(isCover: false))
        .toList();
    items[index] = items[index].copyWith(isCover: true);
    state = state.copyWith(mediaItems: items);
  }

  /// Append video to [mediaItems].
  /// For REEL_VIDEO, replaces any existing video (single-video constraint).
  Future<void> addVideo(
    String originalPath, {
    required Enum$PostMediaRole role,
  }) async {
    _temporaryFilePaths.add(originalPath);

    final file = File(originalPath);
    final bytes = await file.exists() ? await file.length() : 0;
    final mine = FileUtil.getMimeType(originalPath);

    final media = LocalPostMedia(
      localPath: originalPath,
      mimeType: mine ?? 'video/mp4',
      fileSizeBytes: bytes.toDouble(),
      isCover: state.mediaItems.isEmpty,
      role: role,
    );

    // REEL → replace existing video; standard → append
    state = state.copyWith(
      mediaItems: role == Enum$PostMediaRole.REEL_VIDEO
          ? [media]
          : [...state.mediaItems, media],
    );
  }

  // --- Topic / category ---

  void setTopicAndCategory({
    required TopicModel topic,
    CategoryModel? majorCategory,
    CategoryModel? minorCategory,
  }) {
    final oldTopic = state.topic;
    final isQna = topic.isQnA;
    final newFields = Map<CreatePostField, CommonFormFieldState>.from(
      state.fields,
    );

    if (newFields.containsKey(CreatePostField.title)) {
      newFields[CreatePostField.title] = newFields[CreatePostField.title]!
          .copyWith(
            isOptional: isQna,
          );
    }
    if (newFields.containsKey(CreatePostField.description)) {
      newFields[CreatePostField.description] =
          newFields[CreatePostField.description]!.copyWith(
            isOptional: !isQna,
          );
    }

    // Media migration / conversion logic based on old and new topic types
    var newMediaBeforeItems = <LocalPostMedia>[...state.mediaBeforeItems];
    var newMediaAfterItems = <LocalPostMedia>[...state.mediaAfterItems];
    var newMediaItems = <LocalPostMedia>[...state.mediaItems];

    if (oldTopic != null && oldTopic.type != topic.type) {
      final wasBeforeAfter = oldTopic.isBeforeAfter;
      final isBeforeAfter = topic.isBeforeAfter;
      final wasReel = oldTopic.isReel;
      final isReel = topic.isReel;

      if (isBeforeAfter && !wasBeforeAfter) {
        // Migrating from standard/reel to before-after
        // Move whatever was in mediaItems to mediaBeforeItems (set role to BEFORE)
        if (newMediaBeforeItems.isEmpty && newMediaItems.isNotEmpty) {
          newMediaBeforeItems = newMediaItems
              .map(
                (e) => e.copyWith(
                  role: Enum$PostMediaRole.BEFORE,
                ),
              )
              .toList();
          newMediaItems = [];
        }
      } else if (!isBeforeAfter && wasBeforeAfter) {
        // Migrating from before-after to standard/reel
        // Combine mediaBeforeItems and mediaAfterItems into mediaItems (set role to STANDARD or REEL_VIDEO)
        if (newMediaItems.isEmpty) {
          final combined = [...newMediaBeforeItems, ...newMediaAfterItems];
          if (isReel) {
            // REEL only supports a single video. Find the first video, or clear if none
            final firstVideo = combined.firstWhereOrNull((e) => e.isVideo);
            if (firstVideo != null) {
              newMediaItems = [
                firstVideo.copyWith(
                  role: Enum$PostMediaRole.REEL_VIDEO,
                  isCover: true,
                ),
              ];
            } else {
              newMediaItems = [];
            }
          } else {
            // Standard topic: map all to STANDARD
            newMediaItems = combined
                .map(
                  (e) => e.copyWith(
                    role: Enum$PostMediaRole.STANDARD,
                  ),
                )
                .toList();
          }
          newMediaBeforeItems = [];
          newMediaAfterItems = [];
        }
      } else if (isReel && !wasReel) {
        // Standard to REEL: find the first video and convert it
        final firstVideo = newMediaItems.firstWhereOrNull((e) => e.isVideo);
        if (firstVideo != null) {
          newMediaItems = [
            firstVideo.copyWith(
              role: Enum$PostMediaRole.REEL_VIDEO,
              isCover: true,
            ),
          ];
        } else {
          newMediaItems = [];
        }
      } else if (!isReel && wasReel) {
        // REEL to Standard: convert REEL_VIDEO to STANDARD
        newMediaItems = newMediaItems
            .map(
              (e) => e.copyWith(
                role: Enum$PostMediaRole.STANDARD,
              ),
            )
            .toList();
      }
    }

    state = state.copyWith(
      topic: topic,
      majorCategory: majorCategory,
      minorCategory: minorCategory,
      fields: newFields,
      mediaBeforeItems: newMediaBeforeItems,
      mediaAfterItems: newMediaAfterItems,
      mediaItems: newMediaItems,
    );
  }

  void initWithPost(PostModel post) {
    final postStatus = post.status;

    final beforeItems = <LocalPostMedia>[];
    final afterItems = <LocalPostMedia>[];
    final standardItems = <LocalPostMedia>[];

    for (final media in post.mediaItems) {
      final role = media.role ?? Enum$PostMediaRole.STANDARD;
      final localMedia = LocalPostMedia(
        localPath: media.mediaUrl ?? '',
        mimeType: media.mediaType?.isVideo == true ? 'video/mp4' : 'image/jpeg',
        fileSizeBytes: 0,
        isCover: media.isCover,
        role: role,
        uploadedMediaId: media.mediaId,
        isVideo: media.mediaType?.isVideo == true,
      );

      if (role.isBefore) {
        beforeItems.add(localMedia);
      } else if (role.isAfter) {
        afterItems.add(localMedia);
      } else {
        standardItems.add(localMedia);
      }
    }

    state = state.copyWith(
      editPostId: post.id,
      editPostStatus: postStatus,
      originalPost: post,
      topic: post.postTopic,
      majorCategory: post.category?.major != null
          ? CategoryModel(
              id: post.category!.major!.id,
              name: post.category!.major!.name,
              type: Enum$CategoryType.MAJOR,
            )
          : null,
      minorCategory: post.category?.minor != null
          ? CategoryModel(
              id: post.category!.minor!.id,
              name: post.category!.minor!.name,
              type: Enum$CategoryType.MINOR,
            )
          : null,
      tags: post.tags,
      mediaBeforeItems: beforeItems,
      mediaAfterItems: afterItems,
      mediaItems: standardItems,
      fields: {
        CreatePostField.title: CommonFormFieldState<String?>(
          value: post.title,
          isOptional: post.postTopic?.isQnA == true,
        ),
        CreatePostField.description: CommonFormFieldState<String?>(
          value: post.description,
          isOptional: post.postTopic?.isQnA != true,
        ),
      },
    );
  }

  Future<void> initEditMode(String id) async {
    state = state.copyWith(isLoadingPost: true);
    final result = await ref.read(postRepositoryProvider).getPostById(id);
    result.fold(
      onSuccess: (post) {
        state = state.copyWith(isLoadingPost: false);
        initWithPost(post);
      },
      onFailure: (error) {
        state = state.copyWith(
          isLoadingPost: false,
          submitError: error,
        );
      },
    );
  }

  Future<List<Input$PostMediaItemInput>> _uploadNewMediaAndBuildDTO() async {
    final mediaUploadService = ref.read(mediaUploadServiceProvider);

    final allMedia = [
      ...state.mediaBeforeItems,
      ...state.mediaAfterItems,
      ...state.mediaItems,
    ];

    final result = <Input$PostMediaItemInput>[];

    for (var i = 0; i < allMedia.length; i++) {
      final media = allMedia[i];
      var mediaId = media.uploadedMediaId;

      if (mediaId == null) {
        final file = File(media.localPath);
        if (!file.existsSync()) {
          throw AppException.badRequest(
            message: 'Không tìm thấy file: ${media.localPath}',
          );
        }

        if (media.isVideo) {
          mediaId = await mediaUploadService.uploadVideo(file);
        } else {
          mediaId = await mediaUploadService.uploadImage(file);
        }
      }

      result.add(
        Input$PostMediaItemInput(
          mediaId: mediaId,
          role: media.role,
          order: i,
          isCover: media.isCover,
        ),
      );
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Private helpers shared by saveDraft / submitPost
  // ---------------------------------------------------------------------------

  /// Throws [AppException] when a forbidden word is found in [text].
  /// No-op when the composed text is blank.
  Future<void> _checkForbiddenWords(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final result = await ref
        .read(masterDataRepositoryProvider)
        .hasForbiddenWords(
          text: trimmed,
          type: Enum$ForbiddenWordType.CONTENT,
        );
    result.fold(
      onSuccess: (hasForbidden) {
        if (hasForbidden) {
          throw const AppException.badRequest(
            message: ErrorConstants.forbiddenWordFound,
            errorCode: ErrorConstants.forbiddenWordFound,
          );
        }
      },
      onFailure: (error) => throw error,
    );
  }

  /// Flattens all current-state media (before / after / standard) into
  /// Hive-compatible [hive_model.LocalMediaItem]s.
  List<hive_model.LocalMediaItem> _buildLocalMediaItems() {
    return [
          ...state.mediaBeforeItems,
          ...state.mediaAfterItems,
          ...state.mediaItems,
        ]
        .map(
          (media) => hive_model.LocalMediaItem(
            localPath: media.localPath,
            mimeType: media.mimeType,
            fileSizeBytes: media.fileSizeBytes,
            isCover: media.isCover,
            roleString: media.role.name,
            uploadedMediaId: media.uploadedMediaId,
          ),
        )
        .toList();
  }

  /// Enqueues [task], transfers file ownership to BackgroundService, and
  /// emits [SubmissionStatus.success].
  Future<void> _enqueueAndFinish(PostTask task) async {
    await ref.read(backgroundPostServiceProvider).enqueuePost(task);
    _shouldKeepFiles = true;
    state = setStatus(SubmissionStatus.success);
  }

  void _handleSubmitError(Object e) {
    state = setStatus(
      SubmissionStatus.failure,
      error: e is AppException
          ? e
          : const AppException.badRequest(
              message: ErrorConstants.unknownError,
              errorCode: ErrorConstants.unknownError,
            ),
    );
  }

  // ---------------------------------------------------------------------------

  Future<void> saveDraft() async {
    if (state.isSubmitting) return;
    if (!validateForm()) return;

    state = state.copyWith(
      status: SubmissionStatus.submitting,
      submitError: null,
      isDraftSaved: true,
    );

    try {
      if (state.topic == null) {
        throw const AppException.badRequest(
          message: ErrorConstants.unknownError,
          errorCode: ErrorConstants.unknownError,
        );
      }
      final draftCountResult = await ref
          .read(postRepositoryProvider)
          .getDraftCount();
      draftCountResult.when(
        success: (count) {
          if (count >= AppConstants.maxDraftPost) {
            throw const AppException.badRequest(
              message: ErrorConstants.maxDraftExceed,
              errorCode: ErrorConstants.maxDraftExceed,
            );
          }
        },
        failure: (error) => throw error,
      );

      final title = _trimmedField(CreatePostField.title);
      final description = _trimmedField(CreatePostField.description);
      await _checkForbiddenWords(
        '${title ?? ""} ${description ?? ""} ${state.tags.join(", ")}',
      );

      if (state.isEditMode) {
        final mediaDTOs = await _uploadNewMediaAndBuildDTO();
        final input = Input$EditPostInput(
          title: title,
          description: description,
          postTopicId: state.topic?.id,
          categoryMajorId: state.majorCategory?.id,
          categoryMinorId: state.minorCategory?.id,
          mediaItems: mediaDTOs,
          tags: state.tags,
        );
        final result = await ref
            .read(postRepositoryProvider)
            .editPost(
              id: state.editPostId!,
              input: input,
            );
        await result.fold(
          onSuccess: (_) async {
            final updatedPostResult = await ref
                .read(postRepositoryProvider)
                .getPostById(state.editPostId!);
            updatedPostResult.fold(
              onSuccess: (updatedPost) {
                ref.read(postCacheProvider.notifier).updatePost(updatedPost);
              },
              onFailure: (error) {
                Log.e('Failed to fetch updated post after saveDraft: $error');
              },
            );

            ref.read(draftPostsTabControllerProvider.notifier).pullToRefresh();

            state = state.copyWith(isDraftSaved: true);
            state = setStatus(SubmissionStatus.success);
          },
          onFailure: (error) => throw error,
        );
        return;
      }

      await _enqueueAndFinish(_toPostTask(isDraft: true));
    } catch (e) {
      _handleSubmitError(e);
    }
  }

  /// Title/description are stored exactly as typed (free typing in the input);
  /// trim them only here, when building the payload sent to the server.
  String? _trimmedField(CreatePostField field) =>
      getField<String?>(field).value?.trim();

  PostTask _toPostTask({required bool isDraft}) {
    return PostTask(
      id: const Uuid().v4(),
      topicId: state.topic?.id ?? '',
      categoryMajorId: state.majorCategory?.id,
      categoryMinorId: state.minorCategory?.id,
      title: _trimmedField(CreatePostField.title),
      description: _trimmedField(CreatePostField.description),
      localMediaItems: _buildLocalMediaItems(),
      tags: state.tags,
      isDraft: isDraft,
      editPostId: state.editPostId,
    );
  }

  Future<void> submitPost() async {
    if (state.isSubmitting) return;
    if (!validateForm()) return;

    if (state.isEditMode && !state.isEditingDraft && !state.hasPostChanged) {
      state = setStatus(SubmissionStatus.success);
      return;
    }

    state = state.copyWith(
      status: SubmissionStatus.submitting,
      submitError: null,
      isDraftSaved: false,
    );

    try {
      if (state.topic == null) {
        throw const AppException.badRequest(
          message: ErrorConstants.unknownError,
          errorCode: ErrorConstants.unknownError,
        );
      }

      final title = _trimmedField(CreatePostField.title);
      final description = _trimmedField(CreatePostField.description);
      await _checkForbiddenWords(
        '${title ?? ""} ${description ?? ""} ${state.tags.join(", ")}',
      );

      if (state.isEditMode) {
        if (state.isEditingDraft) {
          final mediaDTOs = await _uploadNewMediaAndBuildDTO();
          final input = Input$EditPostInput(
            title: title,
            description: description,
            postTopicId: state.topic?.id,
            categoryMajorId: state.majorCategory?.id,
            categoryMinorId: state.minorCategory?.id,
            mediaItems: mediaDTOs,
            tags: state.tags,
          );
          final result = await ref
              .read(postRepositoryProvider)
              .editPost(
                id: state.editPostId!,
                input: input,
              );
          await result.fold(
            onSuccess: (data) async {
              final publishResult = await ref
                  .read(postRepositoryProvider)
                  .publishPost(state.editPostId!);
              await publishResult.fold(
                onSuccess: (_) async {
                  final updatedPostResult = await ref
                      .read(postRepositoryProvider)
                      .getPostById(state.editPostId!);
                  updatedPostResult.fold(
                    onSuccess: (updatedPost) {
                      ref
                          .read(postCacheProvider.notifier)
                          .updatePost(updatedPost);
                    },
                    onFailure: (error) {
                      Log.e(
                        'Failed to fetch updated post after publishPost: $error',
                      );
                    },
                  );

                  ref
                      .read(draftPostsTabControllerProvider.notifier)
                      .removePostId(state.editPostId!);
                  ref
                      .read(homeBootstrapControllerProvider.notifier)
                      .refreshAll();

                  final topics = ref.read(masterDataControllerProvider).topics;
                  final topic = topics.firstWhereOrNull(
                    (t) => t.id == state.topic?.id,
                  );
                  if (topic != null && topic.type != null) {
                    ref
                        .read(
                          postListControllerProvider(
                            selectedTopic: topic,
                            selectedCategory: state.majorCategory,
                            selectedSubCategory: state.minorCategory,
                          ).notifier,
                        )
                        .pullToRefresh();
                  }
                },
                onFailure: (error) => throw error,
              );
              state = state.copyWith(isDraftSaved: false);
              state = setStatus(SubmissionStatus.success);
            },
            onFailure: (error) => throw error,
          );
          return;
        } else {
          // If editing a published post (not a draft), run background upload & edit task flow (like when creating a post)
          await _enqueueAndFinish(_toPostTask(isDraft: false));
          return;
        }
      }

      await _enqueueAndFinish(_toPostTask(isDraft: false));
    } catch (e) {
      _handleSubmitError(e);
    }
  }

  /// Reset trạng thái submit về idle (gọi sau khi UI đã xử lý error)
  @override
  void clearSubmitError() {
    state = state.copyWith(
      status: SubmissionStatus.idle,
      submitError: null,
    );
  }

  @override
  CreatePostState setStatus(SubmissionStatus status, {AppException? error}) {
    return state.copyWith(status: status, submitError: error);
  }
}

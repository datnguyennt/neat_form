// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_post_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreatePostState {

 Map<CreatePostField, CommonFormFieldState> get fields; List<LocalPostMedia> get mediaBeforeItems; List<LocalPostMedia> get mediaAfterItems;// For non-before-after topics (STANDARD / REEL)
 List<LocalPostMedia> get mediaItems; List<String> get tags; SubmissionStatus get status; bool get isDraftSaved; bool get isLoadingPost;/// Error từ lần submit gần nhất (chỉ dùng cho logging/UI dispatch)
 AppException? get submitError; TopicModel? get topic; CategoryModel? get majorCategory; CategoryModel? get minorCategory; String? get editPostId; Enum$PostStatus? get editPostStatus; PostModel? get originalPost;
/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatePostStateCopyWith<CreatePostState> get copyWith => _$CreatePostStateCopyWithImpl<CreatePostState>(this as CreatePostState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePostState&&const DeepCollectionEquality().equals(other.fields, fields)&&const DeepCollectionEquality().equals(other.mediaBeforeItems, mediaBeforeItems)&&const DeepCollectionEquality().equals(other.mediaAfterItems, mediaAfterItems)&&const DeepCollectionEquality().equals(other.mediaItems, mediaItems)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.status, status) || other.status == status)&&(identical(other.isDraftSaved, isDraftSaved) || other.isDraftSaved == isDraftSaved)&&(identical(other.isLoadingPost, isLoadingPost) || other.isLoadingPost == isLoadingPost)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.majorCategory, majorCategory) || other.majorCategory == majorCategory)&&(identical(other.minorCategory, minorCategory) || other.minorCategory == minorCategory)&&(identical(other.editPostId, editPostId) || other.editPostId == editPostId)&&(identical(other.editPostStatus, editPostStatus) || other.editPostStatus == editPostStatus)&&(identical(other.originalPost, originalPost) || other.originalPost == originalPost));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(fields),const DeepCollectionEquality().hash(mediaBeforeItems),const DeepCollectionEquality().hash(mediaAfterItems),const DeepCollectionEquality().hash(mediaItems),const DeepCollectionEquality().hash(tags),status,isDraftSaved,isLoadingPost,submitError,topic,majorCategory,minorCategory,editPostId,editPostStatus,originalPost);

@override
String toString() {
  return 'CreatePostState(fields: $fields, mediaBeforeItems: $mediaBeforeItems, mediaAfterItems: $mediaAfterItems, mediaItems: $mediaItems, tags: $tags, status: $status, isDraftSaved: $isDraftSaved, isLoadingPost: $isLoadingPost, submitError: $submitError, topic: $topic, majorCategory: $majorCategory, minorCategory: $minorCategory, editPostId: $editPostId, editPostStatus: $editPostStatus, originalPost: $originalPost)';
}


}

/// @nodoc
abstract mixin class $CreatePostStateCopyWith<$Res>  {
  factory $CreatePostStateCopyWith(CreatePostState value, $Res Function(CreatePostState) _then) = _$CreatePostStateCopyWithImpl;
@useResult
$Res call({
 Map<CreatePostField, CommonFormFieldState> fields, List<LocalPostMedia> mediaBeforeItems, List<LocalPostMedia> mediaAfterItems, List<LocalPostMedia> mediaItems, List<String> tags, SubmissionStatus status, bool isDraftSaved, bool isLoadingPost, AppException? submitError, TopicModel? topic, CategoryModel? majorCategory, CategoryModel? minorCategory, String? editPostId, Enum$PostStatus? editPostStatus, PostModel? originalPost
});


$AppExceptionCopyWith<$Res>? get submitError;$TopicModelCopyWith<$Res>? get topic;$CategoryModelCopyWith<$Res>? get majorCategory;$CategoryModelCopyWith<$Res>? get minorCategory;$PostModelCopyWith<$Res>? get originalPost;

}
/// @nodoc
class _$CreatePostStateCopyWithImpl<$Res>
    implements $CreatePostStateCopyWith<$Res> {
  _$CreatePostStateCopyWithImpl(this._self, this._then);

  final CreatePostState _self;
  final $Res Function(CreatePostState) _then;

/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fields = null,Object? mediaBeforeItems = null,Object? mediaAfterItems = null,Object? mediaItems = null,Object? tags = null,Object? status = null,Object? isDraftSaved = null,Object? isLoadingPost = null,Object? submitError = freezed,Object? topic = freezed,Object? majorCategory = freezed,Object? minorCategory = freezed,Object? editPostId = freezed,Object? editPostStatus = freezed,Object? originalPost = freezed,}) {
  return _then(_self.copyWith(
fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as Map<CreatePostField, CommonFormFieldState>,mediaBeforeItems: null == mediaBeforeItems ? _self.mediaBeforeItems : mediaBeforeItems // ignore: cast_nullable_to_non_nullable
as List<LocalPostMedia>,mediaAfterItems: null == mediaAfterItems ? _self.mediaAfterItems : mediaAfterItems // ignore: cast_nullable_to_non_nullable
as List<LocalPostMedia>,mediaItems: null == mediaItems ? _self.mediaItems : mediaItems // ignore: cast_nullable_to_non_nullable
as List<LocalPostMedia>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubmissionStatus,isDraftSaved: null == isDraftSaved ? _self.isDraftSaved : isDraftSaved // ignore: cast_nullable_to_non_nullable
as bool,isLoadingPost: null == isLoadingPost ? _self.isLoadingPost : isLoadingPost // ignore: cast_nullable_to_non_nullable
as bool,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as AppException?,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as TopicModel?,majorCategory: freezed == majorCategory ? _self.majorCategory : majorCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,minorCategory: freezed == minorCategory ? _self.minorCategory : minorCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,editPostId: freezed == editPostId ? _self.editPostId : editPostId // ignore: cast_nullable_to_non_nullable
as String?,editPostStatus: freezed == editPostStatus ? _self.editPostStatus : editPostStatus // ignore: cast_nullable_to_non_nullable
as Enum$PostStatus?,originalPost: freezed == originalPost ? _self.originalPost : originalPost // ignore: cast_nullable_to_non_nullable
as PostModel?,
  ));
}
/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppExceptionCopyWith<$Res>? get submitError {
    if (_self.submitError == null) {
    return null;
  }

  return $AppExceptionCopyWith<$Res>(_self.submitError!, (value) {
    return _then(_self.copyWith(submitError: value));
  });
}/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopicModelCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $TopicModelCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get majorCategory {
    if (_self.majorCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.majorCategory!, (value) {
    return _then(_self.copyWith(majorCategory: value));
  });
}/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get minorCategory {
    if (_self.minorCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.minorCategory!, (value) {
    return _then(_self.copyWith(minorCategory: value));
  });
}/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PostModelCopyWith<$Res>? get originalPost {
    if (_self.originalPost == null) {
    return null;
  }

  return $PostModelCopyWith<$Res>(_self.originalPost!, (value) {
    return _then(_self.copyWith(originalPost: value));
  });
}
}


/// Adds pattern-matching-related methods to [CreatePostState].
extension CreatePostStatePatterns on CreatePostState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatePostState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatePostState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatePostState value)  $default,){
final _that = this;
switch (_that) {
case _CreatePostState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatePostState value)?  $default,){
final _that = this;
switch (_that) {
case _CreatePostState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<CreatePostField, CommonFormFieldState> fields,  List<LocalPostMedia> mediaBeforeItems,  List<LocalPostMedia> mediaAfterItems,  List<LocalPostMedia> mediaItems,  List<String> tags,  SubmissionStatus status,  bool isDraftSaved,  bool isLoadingPost,  AppException? submitError,  TopicModel? topic,  CategoryModel? majorCategory,  CategoryModel? minorCategory,  String? editPostId,  Enum$PostStatus? editPostStatus,  PostModel? originalPost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatePostState() when $default != null:
return $default(_that.fields,_that.mediaBeforeItems,_that.mediaAfterItems,_that.mediaItems,_that.tags,_that.status,_that.isDraftSaved,_that.isLoadingPost,_that.submitError,_that.topic,_that.majorCategory,_that.minorCategory,_that.editPostId,_that.editPostStatus,_that.originalPost);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<CreatePostField, CommonFormFieldState> fields,  List<LocalPostMedia> mediaBeforeItems,  List<LocalPostMedia> mediaAfterItems,  List<LocalPostMedia> mediaItems,  List<String> tags,  SubmissionStatus status,  bool isDraftSaved,  bool isLoadingPost,  AppException? submitError,  TopicModel? topic,  CategoryModel? majorCategory,  CategoryModel? minorCategory,  String? editPostId,  Enum$PostStatus? editPostStatus,  PostModel? originalPost)  $default,) {final _that = this;
switch (_that) {
case _CreatePostState():
return $default(_that.fields,_that.mediaBeforeItems,_that.mediaAfterItems,_that.mediaItems,_that.tags,_that.status,_that.isDraftSaved,_that.isLoadingPost,_that.submitError,_that.topic,_that.majorCategory,_that.minorCategory,_that.editPostId,_that.editPostStatus,_that.originalPost);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<CreatePostField, CommonFormFieldState> fields,  List<LocalPostMedia> mediaBeforeItems,  List<LocalPostMedia> mediaAfterItems,  List<LocalPostMedia> mediaItems,  List<String> tags,  SubmissionStatus status,  bool isDraftSaved,  bool isLoadingPost,  AppException? submitError,  TopicModel? topic,  CategoryModel? majorCategory,  CategoryModel? minorCategory,  String? editPostId,  Enum$PostStatus? editPostStatus,  PostModel? originalPost)?  $default,) {final _that = this;
switch (_that) {
case _CreatePostState() when $default != null:
return $default(_that.fields,_that.mediaBeforeItems,_that.mediaAfterItems,_that.mediaItems,_that.tags,_that.status,_that.isDraftSaved,_that.isLoadingPost,_that.submitError,_that.topic,_that.majorCategory,_that.minorCategory,_that.editPostId,_that.editPostStatus,_that.originalPost);case _:
  return null;

}
}

}

/// @nodoc


class _CreatePostState extends CreatePostState {
  const _CreatePostState({final  Map<CreatePostField, CommonFormFieldState> fields = const {}, final  List<LocalPostMedia> mediaBeforeItems = const [], final  List<LocalPostMedia> mediaAfterItems = const [], final  List<LocalPostMedia> mediaItems = const [], final  List<String> tags = const [], this.status = SubmissionStatus.idle, this.isDraftSaved = false, this.isLoadingPost = false, this.submitError, this.topic, this.majorCategory, this.minorCategory, this.editPostId, this.editPostStatus, this.originalPost}): _fields = fields,_mediaBeforeItems = mediaBeforeItems,_mediaAfterItems = mediaAfterItems,_mediaItems = mediaItems,_tags = tags,super._();
  

 final  Map<CreatePostField, CommonFormFieldState> _fields;
@override@JsonKey() Map<CreatePostField, CommonFormFieldState> get fields {
  if (_fields is EqualUnmodifiableMapView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fields);
}

 final  List<LocalPostMedia> _mediaBeforeItems;
@override@JsonKey() List<LocalPostMedia> get mediaBeforeItems {
  if (_mediaBeforeItems is EqualUnmodifiableListView) return _mediaBeforeItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaBeforeItems);
}

 final  List<LocalPostMedia> _mediaAfterItems;
@override@JsonKey() List<LocalPostMedia> get mediaAfterItems {
  if (_mediaAfterItems is EqualUnmodifiableListView) return _mediaAfterItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaAfterItems);
}

// For non-before-after topics (STANDARD / REEL)
 final  List<LocalPostMedia> _mediaItems;
// For non-before-after topics (STANDARD / REEL)
@override@JsonKey() List<LocalPostMedia> get mediaItems {
  if (_mediaItems is EqualUnmodifiableListView) return _mediaItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaItems);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  SubmissionStatus status;
@override@JsonKey() final  bool isDraftSaved;
@override@JsonKey() final  bool isLoadingPost;
/// Error từ lần submit gần nhất (chỉ dùng cho logging/UI dispatch)
@override final  AppException? submitError;
@override final  TopicModel? topic;
@override final  CategoryModel? majorCategory;
@override final  CategoryModel? minorCategory;
@override final  String? editPostId;
@override final  Enum$PostStatus? editPostStatus;
@override final  PostModel? originalPost;

/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatePostStateCopyWith<_CreatePostState> get copyWith => __$CreatePostStateCopyWithImpl<_CreatePostState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatePostState&&const DeepCollectionEquality().equals(other._fields, _fields)&&const DeepCollectionEquality().equals(other._mediaBeforeItems, _mediaBeforeItems)&&const DeepCollectionEquality().equals(other._mediaAfterItems, _mediaAfterItems)&&const DeepCollectionEquality().equals(other._mediaItems, _mediaItems)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.status, status) || other.status == status)&&(identical(other.isDraftSaved, isDraftSaved) || other.isDraftSaved == isDraftSaved)&&(identical(other.isLoadingPost, isLoadingPost) || other.isLoadingPost == isLoadingPost)&&(identical(other.submitError, submitError) || other.submitError == submitError)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.majorCategory, majorCategory) || other.majorCategory == majorCategory)&&(identical(other.minorCategory, minorCategory) || other.minorCategory == minorCategory)&&(identical(other.editPostId, editPostId) || other.editPostId == editPostId)&&(identical(other.editPostStatus, editPostStatus) || other.editPostStatus == editPostStatus)&&(identical(other.originalPost, originalPost) || other.originalPost == originalPost));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields),const DeepCollectionEquality().hash(_mediaBeforeItems),const DeepCollectionEquality().hash(_mediaAfterItems),const DeepCollectionEquality().hash(_mediaItems),const DeepCollectionEquality().hash(_tags),status,isDraftSaved,isLoadingPost,submitError,topic,majorCategory,minorCategory,editPostId,editPostStatus,originalPost);

@override
String toString() {
  return 'CreatePostState(fields: $fields, mediaBeforeItems: $mediaBeforeItems, mediaAfterItems: $mediaAfterItems, mediaItems: $mediaItems, tags: $tags, status: $status, isDraftSaved: $isDraftSaved, isLoadingPost: $isLoadingPost, submitError: $submitError, topic: $topic, majorCategory: $majorCategory, minorCategory: $minorCategory, editPostId: $editPostId, editPostStatus: $editPostStatus, originalPost: $originalPost)';
}


}

/// @nodoc
abstract mixin class _$CreatePostStateCopyWith<$Res> implements $CreatePostStateCopyWith<$Res> {
  factory _$CreatePostStateCopyWith(_CreatePostState value, $Res Function(_CreatePostState) _then) = __$CreatePostStateCopyWithImpl;
@override @useResult
$Res call({
 Map<CreatePostField, CommonFormFieldState> fields, List<LocalPostMedia> mediaBeforeItems, List<LocalPostMedia> mediaAfterItems, List<LocalPostMedia> mediaItems, List<String> tags, SubmissionStatus status, bool isDraftSaved, bool isLoadingPost, AppException? submitError, TopicModel? topic, CategoryModel? majorCategory, CategoryModel? minorCategory, String? editPostId, Enum$PostStatus? editPostStatus, PostModel? originalPost
});


@override $AppExceptionCopyWith<$Res>? get submitError;@override $TopicModelCopyWith<$Res>? get topic;@override $CategoryModelCopyWith<$Res>? get majorCategory;@override $CategoryModelCopyWith<$Res>? get minorCategory;@override $PostModelCopyWith<$Res>? get originalPost;

}
/// @nodoc
class __$CreatePostStateCopyWithImpl<$Res>
    implements _$CreatePostStateCopyWith<$Res> {
  __$CreatePostStateCopyWithImpl(this._self, this._then);

  final _CreatePostState _self;
  final $Res Function(_CreatePostState) _then;

/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fields = null,Object? mediaBeforeItems = null,Object? mediaAfterItems = null,Object? mediaItems = null,Object? tags = null,Object? status = null,Object? isDraftSaved = null,Object? isLoadingPost = null,Object? submitError = freezed,Object? topic = freezed,Object? majorCategory = freezed,Object? minorCategory = freezed,Object? editPostId = freezed,Object? editPostStatus = freezed,Object? originalPost = freezed,}) {
  return _then(_CreatePostState(
fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as Map<CreatePostField, CommonFormFieldState>,mediaBeforeItems: null == mediaBeforeItems ? _self._mediaBeforeItems : mediaBeforeItems // ignore: cast_nullable_to_non_nullable
as List<LocalPostMedia>,mediaAfterItems: null == mediaAfterItems ? _self._mediaAfterItems : mediaAfterItems // ignore: cast_nullable_to_non_nullable
as List<LocalPostMedia>,mediaItems: null == mediaItems ? _self._mediaItems : mediaItems // ignore: cast_nullable_to_non_nullable
as List<LocalPostMedia>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubmissionStatus,isDraftSaved: null == isDraftSaved ? _self.isDraftSaved : isDraftSaved // ignore: cast_nullable_to_non_nullable
as bool,isLoadingPost: null == isLoadingPost ? _self.isLoadingPost : isLoadingPost // ignore: cast_nullable_to_non_nullable
as bool,submitError: freezed == submitError ? _self.submitError : submitError // ignore: cast_nullable_to_non_nullable
as AppException?,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as TopicModel?,majorCategory: freezed == majorCategory ? _self.majorCategory : majorCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,minorCategory: freezed == minorCategory ? _self.minorCategory : minorCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,editPostId: freezed == editPostId ? _self.editPostId : editPostId // ignore: cast_nullable_to_non_nullable
as String?,editPostStatus: freezed == editPostStatus ? _self.editPostStatus : editPostStatus // ignore: cast_nullable_to_non_nullable
as Enum$PostStatus?,originalPost: freezed == originalPost ? _self.originalPost : originalPost // ignore: cast_nullable_to_non_nullable
as PostModel?,
  ));
}

/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppExceptionCopyWith<$Res>? get submitError {
    if (_self.submitError == null) {
    return null;
  }

  return $AppExceptionCopyWith<$Res>(_self.submitError!, (value) {
    return _then(_self.copyWith(submitError: value));
  });
}/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TopicModelCopyWith<$Res>? get topic {
    if (_self.topic == null) {
    return null;
  }

  return $TopicModelCopyWith<$Res>(_self.topic!, (value) {
    return _then(_self.copyWith(topic: value));
  });
}/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get majorCategory {
    if (_self.majorCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.majorCategory!, (value) {
    return _then(_self.copyWith(majorCategory: value));
  });
}/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get minorCategory {
    if (_self.minorCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.minorCategory!, (value) {
    return _then(_self.copyWith(minorCategory: value));
  });
}/// Create a copy of CreatePostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PostModelCopyWith<$Res>? get originalPost {
    if (_self.originalPost == null) {
    return null;
  }

  return $PostModelCopyWith<$Res>(_self.originalPost!, (value) {
    return _then(_self.copyWith(originalPost: value));
  });
}
}

// dart format on

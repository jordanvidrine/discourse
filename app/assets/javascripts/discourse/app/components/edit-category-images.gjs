import EmberObject, { action } from "@ember/object";
import { buildCategoryPanel } from "discourse/components/edit-category-panel";
import discourseComputed from "discourse/lib/decorators";

export default class EditCategoryImages extends buildCategoryPanel("images") {
  @discourseComputed("category.uploaded_background.url")
  backgroundImageUrl(uploadedBackgroundUrl) {
    return uploadedBackgroundUrl || "";
  }

  @discourseComputed("category.uploaded_background_dark.url")
  backgroundDarkImageUrl(uploadedBackgroundDarkUrl) {
    return uploadedBackgroundDarkUrl || "";
  }

  @discourseComputed("category.uploaded_logo.url")
  logoImageUrl(uploadedLogoUrl) {
    return uploadedLogoUrl || "";
  }

  @discourseComputed("category.uploaded_logo_dark.url")
  logoImageDarkUrl(uploadedLogoDarkUrl) {
    return uploadedLogoDarkUrl || "";
  }

  @action
  logoUploadDone(upload) {
    this._setFromUpload("category.uploaded_logo", upload);
  }

  @action
  logoUploadDeleted() {
    this._deleteUpload("category.uploaded_logo");
  }

  @action
  logoDarkUploadDone(upload) {
    this._setFromUpload("category.uploaded_logo_dark", upload);
  }

  @action
  logoDarkUploadDeleted() {
    this._deleteUpload("category.uploaded_logo_dark");
  }

  @action
  backgroundUploadDone(upload) {
    this._setFromUpload("category.uploaded_background", upload);
  }

  @action
  backgroundUploadDeleted() {
    this._deleteUpload("category.uploaded_background");
  }

  @action
  backgroundDarkUploadDone(upload) {
    this._setFromUpload("category.uploaded_background_dark", upload);
  }

  @action
  backgroundDarkUploadDeleted() {
    this._deleteUpload("category.uploaded_background_dark");
  }

  _deleteUpload(path) {
    this.set(
      path,
      EmberObject.create({
        id: null,
        url: null,
      })
    );
  }

  _setFromUpload(path, upload) {
    this.set(
      path,
      EmberObject.create({
        url: upload.url,
        id: upload.id,
      })
    );
  }
}

<section class="field category-logo">
  <label>{{i18n "category.logo"}}</label>
  <UppyImageUploader
    @imageUrl={{this.logoImageUrl}}
    @onUploadDone={{action "logoUploadDone"}}
    @onUploadDeleted={{action "logoUploadDeleted"}}
    @type="category_logo"
    @id="category-logo-uploader"
    class="no-repeat contain-image"
  />
  <div class="category-logo-description">
    {{i18n "category.logo_description"}}
  </div>
</section>

<section class="field category-logo">
  <label>{{i18n "category.logo_dark"}}</label>
  <UppyImageUploader
    @imageUrl={{this.logoImageDarkUrl}}
    @onUploadDone={{action "logoDarkUploadDone"}}
    @onUploadDeleted={{action "logoDarkUploadDeleted"}}
    @type="category_logo_dark"
    @id="category-dark-logo-uploader"
    class="no-repeat contain-image"
  />
  <div class="category-logo-description">
    {{i18n "category.logo_description"}}
  </div>
</section>

<section class="field category-background-image">
  <label>{{i18n "category.background_image"}}</label>
  <UppyImageUploader
    @imageUrl={{this.backgroundImageUrl}}
    @onUploadDone={{action "backgroundUploadDone"}}
    @onUploadDeleted={{action "backgroundUploadDeleted"}}
    @type="category_background"
    @id="category-background-uploader"
  />
</section>

<section class="field category-background-image">
  <label>{{i18n "category.background_image_dark"}}</label>
  <UppyImageUploader
    @imageUrl={{this.backgroundDarkImageUrl}}
    @onUploadDone={{action "backgroundDarkUploadDone"}}
    @onUploadDeleted={{action "backgroundDarkUploadDeleted"}}
    @type="category_background_dark"
    @id="category-dark-background-uploader"
  />
</section>
/// Cloudinary settings — fill these from your Cloudinary dashboard.
///
/// Setup:
/// 1. https://cloudinary.com → sign up / login
/// 2. Dashboard → copy **Cloud name**
/// 3. Settings → Upload → Add upload preset
///    - Signing mode: **Unsigned**
///    - Name: e.g. `fixxi_unsigned`
/// 4. Paste values below and save this file.
class CloudinaryConfig {
  static const cloudName = 'ye59ycjk';
  static const uploadPreset = 'fixxi_unsigned';

  static bool get isConfigured => cloudName.isNotEmpty && uploadPreset.isNotEmpty;
}

# Библия с паузами

Приложение для iOS, позволяющее пользователю прослушивать различные озвучки Библии с паузами между абзацами/стихами. Паузы помогают более вдумчиво воспринимать слышимую информацию. Особенностью приложения является то, что оно позволяет прослушивать текст, прочитанный несколькими известными дикторами.

# Примечания для разработки

**OpenApi Generation**

- https://swiftpackageindex.com/apple/swift-openapi-generator/1.3.0/tutorials/swift-openapi-generator/clientxcode
- https://developer.apple.com/videos/play/wwdc2023/10171/
- https://www.doctave.com/blog/python-export-fastapi-openapi-spec

# Configuration Setup

## Initial Setup

After cloning this repository, you need to create your local configuration file:

1. Copy the example configuration file:
   ```bash
   cp Bible/Configuration.plist.example Bible/Configuration.plist
   ```

2. Edit `Bible/Configuration.plist` and replace `your-api-key-here` with your actual API key.

3. The `Configuration.plist` file is gitignored and will not be committed to the repository.

## Configuration Structure

The `Configuration.plist` file contains:
- **BaseURL**: The base URL for the Bible API (default: `https://bibleapi.space`)
- **APIKey**: Your personal API key for accessing the Bible API

## Important Notes

- **Never commit** `Configuration.plist` to git - it contains sensitive data
- Always use `Configuration.plist.example` as a template for new developers
- If you need to change the API endpoint or add new configuration values, update both files



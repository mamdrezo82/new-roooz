$ErrorActionPreference = 'Stop'
$javaRoot = Join-Path (Get-Location) 'android\app\src\main\java\com\roozyar\personal'
New-Item -ItemType Directory -Force -Path $javaRoot | Out-Null
$pluginPath = Join-Path $javaRoot 'RoozYarSaveFilePlugin.java'
$plugin = @'
package com.roozyar.personal;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import com.getcapacitor.ActivityResult;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;

@CapacitorPlugin(name = "RoozYarSaveFile")
public class RoozYarSaveFilePlugin extends Plugin {
    @PluginMethod
    public void save(PluginCall call) {
        String fileName = call.getString("fileName", "roozyar-backup.json");
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("application/json");
        intent.putExtra(Intent.EXTRA_TITLE, fileName);
        startActivityForResult(call, intent, "handleSaveResult");
    }

    @ActivityCallback
    private void handleSaveResult(PluginCall call, ActivityResult result) {
        if (call == null) return;
        if (result.getResultCode() != Activity.RESULT_OK || result.getData() == null || result.getData().getData() == null) {
            call.reject("Save cancelled");
            return;
        }
        Uri uri = result.getData().getData();
        String content = call.getString("content", "");
        try (OutputStream output = getContext().getContentResolver().openOutputStream(uri);
             OutputStreamWriter writer = new OutputStreamWriter(output, StandardCharsets.UTF_8)) {
            writer.write(content);
            writer.flush();
            JSObject ret = new JSObject();
            ret.put("uri", uri.toString());
            call.resolve(ret);
        } catch (Exception ex) {
            call.reject("Could not save backup", ex);
        }
    }
}
'@
[System.IO.File]::WriteAllText($pluginPath, $plugin, (New-Object System.Text.UTF8Encoding($false)))
$mainPath = Join-Path $javaRoot 'MainActivity.java'
if (-not (Test-Path $mainPath)) { throw "MainActivity.java پیدا نشد: $mainPath" }
$main = Get-Content $mainPath -Raw
if ($main -notmatch 'RoozYarSaveFilePlugin') {
  if ($main -notmatch 'import android.os.Bundle;') { $main = $main -replace 'package com\.roozyar\.personal;\s*', "package com.roozyar.personal;`r`n`r`nimport android.os.Bundle;`r`n" }
  $main = $main -replace 'import com\.getcapacitor\.BridgeActivity;', "import com.getcapacitor.BridgeActivity;`r`nimport com.roozyar.personal.RoozYarSaveFilePlugin;"
  $main = $main -replace 'public class MainActivity extends BridgeActivity\s*\{\s*\}', "public class MainActivity extends BridgeActivity {`r`n    @Override`r`n    public void onCreate(Bundle savedInstanceState) {`r`n        registerPlugin(RoozYarSaveFilePlugin.class);`r`n        super.onCreate(savedInstanceState);`r`n    }`r`n}"
  [System.IO.File]::WriteAllText($mainPath, $main, (New-Object System.Text.UTF8Encoding($false)))
}
Write-Host 'افزونه انتخاب مسیر ذخیره پشتیبان آماده شد.' -ForegroundColor Green

# SpecForge SDK サンプルプロジェクト

このディレクトリには、SpecForge Python SDKの機能を実演する完全な例が含まれています。

## ファイル

- `temperature_monitoring.lilo` - 温度監視のためのサンプル仕様
- `sensor_data.csv` - サンプルセンサーデータ（温度と湿度を含む31のデータポイント）
- `demo.ipynb` - すべてのSDK機能を実演するJupyterノートブック
- `temperature_config.json` - 温度監視例のための設定ファイル（パラメーター）
- `util.lilo` - サンプル仕様のためのユーティリティ関数

## セットアップ

**Note:** 以下、ユーザーは `temperature_sensor` フォルダをVSCodeで開くことを推奨します。

### 1. 仮想環境の作成とアクティベート

一般的に（必須ではありませんが）、仮想環境でこれを行うことが推奨されます。以下の手順に従ってください：

```bash
# サンプルプロジェクトディレクトリに移動
cd temperature_sensor

# 仮想環境を作成
python -m venv .venv

# 仮想環境をアクティベート
# Windowsの場合：
.venv\Scripts\activate
# macOS/Linuxの場合：
source .venv/bin/activate
```

### 2\. 依存関係のインストール

```bash
# SpecForge SDK Wheelをインストール
pip install ../specforge_sdk-xxx.whl

# サンプルプロジェクトの追加依存関係をインストール
pip install jupyter pandas matplotlib numpy
```

### 3\. インストールの確認

```bash
# SDKが正しくインストールされたかを確認
python -c "from specforge_sdk import SpecForgeClient; print('✓ SDKが正常にインストールされました')"
```

## サンプル例の実行

### 前提条件

1.  SpecForge APIサーバーが `http://localhost:8080/health` で実行中であることを確認してください。
2.  仮想環境をアクティベートしてください\*\*（まだアクティブでない場合）：
    ```bash
    # Windowsの場合：
    venv\Scripts\activate
    # macOS/Linuxの場合：
    source venv/bin/activate
    ```

### サンプル例の実行

拡張機能が機能していることを確認するには、`demo.ipynb` のセルを実行します。監視コマンドの出力には視覚化が含まれているはずです。

ノートブックが正しいPythonカーネルに接続されていることを確認する必要があるかもしれません。多くの場合、`.venv (Python3.X.X)` または `ipykernel` です。これはVSCodeのノートブックインターフェースから設定できます。

## サンプルデータの概要

含まれている `sensor_data.csv` には以下が含まれています：

- 31の時点（0.0から30.0）
- 温度の読み取り値（20.8°Cから25.0°C）
- 湿度の読み取り値（40.9%から51.5%）

このデータは、温度の境界、安定性、および湿度との相関を含むさまざまな仕様をテストするために設計されています。

## 環境の非アクティベート

サンプルプロジェクトでの作業が完了したら：

```bash
deactivate
```

## トラブルシューティング

### よくある問題

1.  **「Module not found」エラー**: 仮想環境がアクティベートされ、SDKが `pip install ../specforge_sdk-xxx.whl` でインストールされていることを確認してください。
2.  **接続拒否**: SpecForge APIサーバーが `http://localhost:8080/health` で実行されていることを確認してください。
3.  **Jupyterが見つからない**: アクティベートされた仮想環境で `pip install jupyter` を実行してインストールしてください。
4.  **サンプルファイルが見つからない**: `temperature_sensor` ディレクトリにいることを確認してください。

### セットアップの確認

```bash
# Python環境を確認
which python
pip list | grep specforge

# API接続をテスト
python -c "from specforge_sdk import SpecForgeClient; client = SpecForgeClient(); print('Health check:', client.health_check())"
```

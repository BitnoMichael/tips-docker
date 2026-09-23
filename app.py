import os
import subprocess
import tempfile
import shutil
from pathlib import Path
import gradio as gr

# Путь к скрипту TIPs.py
TIPS_SCRIPT = "/app/TIPs.py"

def run_tips(input_file):
    """
    Принимает загруженный .nii.gz файл, запускает пайплайн TIPs,
    возвращает путь к результату.
    """
    if input_file is None:
        return None, "Файл не загружен"

    # Создаём временную рабочую директорию
    work_dir = tempfile.mkdtemp(prefix="tips_")
    input_dir = Path(work_dir) / "input"
    input_dir.mkdir()

    # Копируем входной файл
    input_path = Path(input_file.name)
    target_input = input_dir / "case.nii.gz"
    shutil.copy(input_path, target_input)

    # TIPs.py ожидает путь к ПАПКЕ с файлами .nii.gz
    # и создаёт выходные папки рядом с ней (относительные пути)
    # Поэтому запускаем его из work_dir
    try:
        result = subprocess.run(
            ["python3", TIPS_SCRIPT, str(input_dir)],
            capture_output=True,
            text=True,
            timeout=1800,  # 30 минут
            cwd=work_dir,  # Рабочая директория = временная
            env={
                **os.environ,
                "nnUNet_results": "/app/nnResults",
                "MKL_THREADING_LAYER": "GNU",
                "MKL_SERVICE_FORCE_INTEL": "1",
            }
        )

        if result.returncode != 0:
            return None, f"Ошибка:\n{result.stderr[-2000:]}"

        # Ищем результат — папку с инстанс-сегментацией пульпы
        # (это финальный выход пайплайна)
        output_dirs = list(Path(work_dir).glob("*_resample_pulps_instance"))
        if not output_dirs:
            return None, f"Результат не найден. Лог:\n{result.stdout[-2000:]}"

        output_files = list(output_dirs[0].glob("*.nii.gz"))
        if not output_files:
            return None, "Выходные файлы не найдены"

        # Возвращаем первый файл
        return str(output_files[0]), "Готово!"

    except subprocess.TimeoutExpired:
        return None, "Превышено время ожидания (30 минут)"
    except Exception as e:
        return None, f"Ошибка: {e}"

# Интерфейс Gradio
with gr.Blocks(title="TIPs — Tooth & Pulp Segmentation") as demo:
    gr.Markdown("# TIPs: Tooth Instances and Pulp Segmentation from CBCT")
    gr.Markdown("Загрузите CBCT-снимок в формате `.nii.gz` и получите сегментацию зубов и пульпы.")

    with gr.Row():
        input_file = gr.File(label="Входной CBCT (.nii.gz)", file_types=[".nii.gz", ".nii"])
        output_file = gr.File(label="Результат (.nii.gz)")
        status = gr.Textbox(label="Статус", interactive=False)

    run_btn = gr.Button("Запустить сегментацию", variant="primary")
    run_btn.click(fn=run_tips, inputs=input_file, outputs=[output_file, status])

demo.launch(server_name="0.0.0.0", server_port=7860)
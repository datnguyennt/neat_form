import base64
import json
import os
import urllib.request

diagrams = {
    # 1. Architecture Flowchart (VI & EN)
    "architecture_vi": """flowchart TD
    subgraph UI["🎨 UI Layer (Zero UI Coupling)"]
        Input["TextField / Custom Inputs"]
        Btn["Submit Button / Action UI"]
    end

    subgraph StateMgmt["⚡ State Management Layer"]
        direction TB
        Riverpod["Riverpod Notifier<br/>(NeatFormNotifierMixin)"]
        Bloc["BLoC / Cubit<br/>(NeatFormCubitMixin)"]
        Native["Flutter Native<br/>(NeatFormController)"]
    end

    subgraph CoreEngine["🧠 neat_form Core Engine"]
        direction TB
        Validators["Validation Engine<br/>• 25+ Built-in Rules<br/>• Cross-field (match, when)<br/>• Async Token Engine"]
        FormState["NeatFormState&lt;K&gt;<br/>• Immutable Map&lt;K, NeatFieldState&gt;<br/>• Type-Safe Generics (K Enum)"]
        Lifecycle["Submission Lifecycle<br/>(idle ➔ submitting ➔ success / failure)"]
        Resolver["NeatErrorResolver<br/>(i18n & Param Interpolation)"]
        Observer["NeatFormObserver&lt;K&gt;<br/>(Analytics & Telemetry)"]
    end

    Input -->|"1. User types (onChanged)"| StateMgmt
    Btn -->|"2. Trigger submitForm()"| StateMgmt
    StateMgmt -->|"3. Execute validation"| Validators
    Validators -->|"4. Produce Immutable State"| FormState
    FormState -->|"5. Update Lifecycle"| Lifecycle
    Lifecycle -.->|"Emit events"| Observer
    FormState -->|"Resolve error strings"| Resolver
    FormState ==>|"6. Surgical Rebuild (select / watch)"| UI""",

    "architecture_en": """flowchart TD
    subgraph UI["🎨 UI Layer (Zero UI Coupling)"]
        Input["TextField / Custom Inputs"]
        Btn["Submit Button / Action UI"]
    end

    subgraph StateMgmt["⚡ State Management Layer"]
        direction TB
        Riverpod["Riverpod Notifier<br/>(NeatFormNotifierMixin)"]
        Bloc["BLoC / Cubit<br/>(NeatFormCubitMixin)"]
        Native["Flutter Native<br/>(NeatFormController)"]
    end

    subgraph CoreEngine["🧠 neat_form Core Engine"]
        direction TB
        Validators["Validation Engine<br/>• 25+ Built-in Rules<br/>• Cross-field (match, when)<br/>• Async Token Engine"]
        FormState["NeatFormState&lt;K&gt;<br/>• Immutable Map&lt;K, NeatFieldState&gt;<br/>• Type-Safe Generics (K Enum)"]
        Lifecycle["Submission Lifecycle<br/>(idle ➔ submitting ➔ success / failure)"]
        Resolver["NeatErrorResolver<br/>(i18n & Param Interpolation)"]
        Observer["NeatFormObserver&lt;K&gt;<br/>(Analytics & Telemetry)"]
    end

    Input -->|"1. User types (onChanged)"| StateMgmt
    Btn -->|"2. Trigger submitForm()"| StateMgmt
    StateMgmt -->|"3. Execute validation"| Validators
    Validators -->|"4. Produce Immutable State"| FormState
    FormState -->|"5. Update Lifecycle"| Lifecycle
    Lifecycle -.->|"Emit events"| Observer
    FormState -->|"Resolve error strings"| Resolver
    FormState ==>|"6. Surgical Rebuild (select / watch)"| UI""",

    # 2. Ecosystem Matrix
    "ecosystem_vi": """graph LR
    Core["neat_form Core"]
    
    Core -->|1 Mixin| R1["Riverpod Notifier"]
    Core -->|Nested Mixin| R2["Riverpod + Freezed Screen State"]
    Core -->|Cubit Mixin| B1["BLoC / Cubit"]
    Core -->|Nested Cubit Mixin| B2["Cubit + Freezed Screen State"]
    Core -->|ChangeNotifier| N1["Flutter Native (ListenableBuilder)"]
    Core -->|Pure State Model| O1["Signals / MobX / GetX"]""",

    "ecosystem_en": """graph LR
    Core["neat_form Core"]
    
    Core -->|1 Mixin| R1["Riverpod Notifier"]
    Core -->|Nested Mixin| R2["Riverpod + Freezed Screen State"]
    Core -->|Cubit Mixin| B1["BLoC / Cubit"]
    Core -->|Nested Cubit Mixin| B2["Cubit + Freezed Screen State"]
    Core -->|ChangeNotifier| N1["Flutter Native (ListenableBuilder)"]
    Core -->|Pure State Model| O1["Signals / MobX / GetX"]""",

    # 3. Lifecycle State Machine
    "lifecycle_vi": """stateDiagram-v2
    [*] --> idle : Khởi tạo Form (Initial State)

    idle --> validating : Người dùng bấm Submit (submitForm)
    
    state validating <<choice>>
    validating --> idle : Form có lỗi (showError = true)
    validating --> submitting : Toàn bộ trường hợp lệ (All Valid)

    state submitting {
        [*] --> executing_callback : Thực thi onSubmit(values)
    }

    submitting --> success : onSubmit() thành công
    submitting --> failure : onSubmit() ném lỗi (Catch error)

    success --> idle : resetForm()
    failure --> idle : resetForm() / User chỉnh sửa""",

    "lifecycle_en": """stateDiagram-v2
    [*] --> idle : Form Initialized (Initial State)

    idle --> validating : User Triggers Submit (submitForm)
    
    state validating <<choice>>
    validating --> idle : Form Has Errors (showError = true)
    validating --> submitting : All Fields Valid

    state submitting {
        [*] --> executing_callback : Execute onSubmit(values)
    }

    submitting --> success : onSubmit() Completed Successfully
    submitting --> failure : onSubmit() Threw Exception / Error

    success --> idle : resetForm()
    failure --> idle : User Modifies Field / Retries""",

    # 4. Async Sequence Diagram
    "async_sequence_vi": """sequenceDiagram
    autonumber
    actor User as Người dùng (Gõ phím)
    participant Field as NeatForm / FieldState
    participant Engine as Async Token Engine
    participant API as Server / Backend API

    User->>Field: Gõ "alex" (Request 1)
    Field->>Engine: validateFieldAsync("alex", token = 1)
    Engine->>API: Gọi API kiểm tra "alex" (Mạng trễ: 500ms)

    User->>Field: Gõ tiếp "alexander" (Request 2)
    Field->>Engine: validateFieldAsync("alexander", token = 2)
    Engine->>API: Gọi API kiểm tra "alexander" (Mạng nhanh: 100ms)

    API-->>Engine: Kết quả cho token = 2 (Hợp lệ)
    Engine->>Engine: So khớp token: 2 == 2 (Token mới nhất ✅)
    Engine->>Field: Cập nhật FieldState (Hợp lệ!)

    API-->>Engine: Kết quả cho token = 1 (Tên đã tồn tại)
    Engine->>Engine: So khớp token: 1 != 2 (Token đã cũ / Stale ❌)
    Note over Engine,Field: Tự động hủy kết quả cũ! Giao diện không bị ghi đè sai.""",

    "async_sequence_en": """sequenceDiagram
    autonumber
    actor User as User (Typing)
    participant Field as NeatForm / FieldState
    participant Engine as Async Token Engine
    participant API as Backend Server / API

    User->>Field: Types "alex" (Request 1)
    Field->>Engine: validateFieldAsync("alex", token = 1)
    Engine->>API: HTTP Check "alex" (Slow network: 500ms)

    User->>Field: Types "alexander" (Request 2)
    Field->>Engine: validateFieldAsync("alexander", token = 2)
    Engine->>API: HTTP Check "alexander" (Fast network: 100ms)

    API-->>Engine: Response for token = 2 (Valid)
    Engine->>Engine: Match token: 2 == 2 (Current Token ✅)
    Engine->>Field: Update FieldState (Valid!)

    API-->>Engine: Response for token = 1 (Username taken)
    Engine->>Engine: Match token: 1 != 2 (Stale Token ❌)
    Note over Engine,Field: Outdated response safely discarded! UI is never overwritten."""
}

os.makedirs("doc/diagrams", exist_ok=True)

for name, code in diagrams.items():
    print(f"Generating SVG for {name}...")
    data = {
        "code": code.strip(),
        "mermaid": {
            "theme": "default",
            "themeVariables": {
                "fontFamily": "Inter, Roboto, sans-serif",
                "fontSize": "14px"
            }
        }
    }
    encoded = base64.urlsafe_b64encode(json.dumps(data).encode("utf-8")).decode("utf-8").replace("=", "")
    url = f"https://mermaid.ink/svg/{encoded}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as resp:
        svg_content = resp.read().decode("utf-8")
        filepath = f"doc/diagrams/{name}.svg"
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(svg_content)
        print(f"Saved {filepath} ({len(svg_content)} bytes)")

print("All diagrams generated successfully!")

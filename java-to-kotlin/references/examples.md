# Java to Kotlin Conversion Examples

## Example 1: Simple Activity with findViewById

### Java Source
```java
package com.example.app;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

public class MainActivity extends BaseActivity {
    private TextView title;
    private Button button;
    private String name = "User";

    @Override
    public void initView() {
        title = findViewById(R.id.title);
        button = findViewById(R.id.button);
    }

    @Override
    public void initData(Bundle savedInstanceState) {
        title.setText("Hello " + name);
        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });
    }
}
```

### Kotlin with ViewBinding
```kotlin
package com.example.app

import android.os.Bundle
import com.example.app.databinding.ActivityMainBinding

class MainActivity : BaseActivity<ActivityMainBinding>() {
    private var name = "User"

    override fun initView() {
        super.initView()
        // ViewBinding handles view initialization
    }

    override fun initData(savedInstanceState: Bundle?) {
        mBinding.title.text = "Hello $name"
        mBinding.button.setOnClickListener {
            finish()
        }
    }

    override fun getBinding(
        inflater: LayoutInflater,
        container: ViewGroup?,
        attachToRoot: Boolean
    ): ActivityMainBinding {
        return ActivityMainBinding.inflate(inflater, container, attachToRoot)
    }
}
```

## Example 2: RecyclerView Adapter

### Java Source
```java
public class MyAdapter extends RecyclerView.Adapter<MyAdapter.ViewHolder> {
    private List<String> items;
    private OnItemClickListener listener;

    public interface OnItemClickListener {
        void onItemClick(int position, String item);
    }

    public MyAdapter(List<String> items) {
        this.items = items;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_layout, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        String item = items.get(position);
        holder.text.setText(item);
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (listener != null) {
                    listener.onItemClick(position, item);
                }
            }
        });
    }

    @Override
    public int getItemCount() {
        return items == null ? 0 : items.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView text;

        ViewHolder(View itemView) {
            super(itemView);
            text = itemView.findViewById(R.id.text);
        }
    }
}
```

### Kotlin
```kotlin
class MyAdapter(private val items: List<String>) : 
    RecyclerView.Adapter<MyAdapter.ViewHolder>() {
    
    private var listener: OnItemClickListener? = null

    interface OnItemClickListener {
        fun onItemClick(position: Int, item: String)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_layout, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]
        holder.text.text = item
        holder.itemView.setOnClickListener {
            listener?.onItemClick(position, item)
        }
    }

    override fun getItemCount(): Int = items.size

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val text: TextView = itemView.findViewById(R.id.text)
    }
}
```

## Example 3: RxJava Subscription

### Java Source
```java
private void loadData() {
    HashMap<String, Object> params = new HashMap<>();
    params.put("service", "GetData");
    params.put("id", "123");

    getRxManager().add(
        ApiClient.getData(params)
            .subscribe(new BaseSubscriber<DataEntity>() {
                @Override
                public void onSuccess(DataEntity entity) {
                    if (entity != null && entity.getData() != null) {
                        updateUI(entity.getData());
                    }
                }

                @Override
                public void onFailed(Throwable e) {
                    ToastUtil.show(e.getMessage());
                }
            })
    );
}
```

### Kotlin
```kotlin
private fun loadData() {
    val params = HashMap<String, Any>()
    params["service"] = "GetData"
    params["id"] = "123"

    rxManager.add(
        ApiClient.getData(params)
            .subscribe(object : BaseSubscriber<DataEntity>() {
                override fun onSuccess(entity: DataEntity?) {
                    entity?.data?.let { updateUI(it) }
                }

                override fun onFailed(e: Throwable) {
                    ToastUtil.show(e.message)
                }
            })
    )
}
```

## Example 4: Dialog with Callback

### Java Source
```java
public class MyDialog {
    private DialogUtil dialogUtil;
    private Callback callback;

    public interface Callback {
        void onResult(boolean success);
    }

    public MyDialog(Activity activity) {
        dialogUtil = DialogUtil.getInstance(activity);
        dialogUtil.setContentView(R.layout.dialog_layout);
    }

    public void show() {
        dialogUtil.getView().findViewById(R.id.btn_ok).setOnClickListener(
            new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (callback != null) {
                        callback.onResult(true);
                    }
                    dialogUtil.dismiss();
                }
            }
        );
        dialogUtil.show();
    }

    public void setCallback(Callback callback) {
        this.callback = callback;
    }
}
```

### Kotlin
```kotlin
class MyDialog(activity: Activity) {
    private val dialogUtil = DialogUtil.getInstance(activity)
    private var callback: Callback? = null

    interface Callback {
        fun onResult(success: Boolean)
    }

    init {
        dialogUtil.setContentView(R.layout.dialog_layout)
    }

    fun show() {
        dialogUtil.view?.findViewById<View>(R.id.btn_ok)?.setOnClickListener {
            callback?.onResult(true)
            dialogUtil.dismiss()
        }
        dialogUtil.show()
    }

    fun setCallback(callback: Callback) {
        this.callback = callback
    }
}
```

## Common Pitfalls

### 1. Nullable Return Types
```java
// Java
String value = getIntent().getStringExtra("key");
```
```kotlin
// Kotlin - returns String?
val value = intent.getStringExtra("key") ?: ""
```

### 2. Private Fields in Java Entities
```java
// Java entity with private field
private String WL_order_id;
public String getWL_order_id() { return WL_order_id; }
```
```kotlin
// Kotlin - use getter
val wlOrderId = entity.getWL_order_id()
```

### 3. Method Signature Matching
```java
// Java base class
public void onClick(View v) { }
```
```kotlin
// Kotlin - match nullable parameter
override fun onClick(v: View?) { }
```

### 4. Static Methods
```java
// Java
ClickUtil.checkClickTime();
```
```kotlin
// Kotlin - same syntax for static methods
ClickUtil.checkClickTime()
```

### 5. Collection Checks
```java
// Java
if (list != null && !list.isEmpty()) { }
```
```kotlin
// Kotlin
if (!list.isNullOrEmpty()) { }
```

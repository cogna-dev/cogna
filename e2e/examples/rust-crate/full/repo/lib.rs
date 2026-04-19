pub mod inner {
    pub struct InnerStruct {
        pub value: i32,
    }
}

pub use crate::inner::InnerStruct as ExposedStruct;
pub(crate) use crate::inner::InnerStruct as CrateStruct;

#[deprecated(note = "use ApiItem::new")]
pub struct ApiItem<T>
where
    T: Clone,
{
    pub field: T,
    hidden: i32,
}

pub enum Status {
    Ready,
    Busy,
}

pub union Number {
    pub int_value: i64,
    pub float_value: f64,
}

pub trait Service<T>
where
    T: Clone,
{
    type Output;
    const VERSION: u32;
    fn call(&self, input: T) -> Self::Output;
}

pub const API_VERSION: u32 = 1;
pub static MAX_RETRIES: u8 = 3;

impl<T> ApiItem<T>
where
    T: Clone,
{
    pub fn new(field: T) -> Self {
        Self { field, hidden: 0 }
    }
}

impl<T> Service<T> for ApiItem<T>
where
    T: Clone,
{
    type Output = T;
    const VERSION: u32 = API_VERSION;

    fn call(&self, _input: T) -> Self::Output {
        self.field.clone()
    }
}

pub async fn load_value<T>(value: T) -> T
where
    T: Clone,
{
    value
}

pub struct Borrowed<'a, const N: usize> {
    pub slice: &'a [u8; N],
}

pub unsafe fn dangerous() -> i32 {
    42
}

pub extern "C" fn c_add(a: i32, b: i32) -> i32 {
    a + b
}

pub type Id = u64;

#[macro_export]
macro_rules! make_status {
    () => {
        $crate::Status::Ready
    };
}

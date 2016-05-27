# HSPicker
Picker with search bar at the top. It cab be fed any custom data. Ready made Sectioning.

[![](https://github.com/hemant3370/HSPicker/blob/master/demo.png)](https://github.com/hemant3370/HSPicker/blob/master/demo.png)

How to use:
     
     let picker = HSPicker { (name) -> () in
                       
                    }
                    
                    // Pass your data
                    picker.dataSource = List.names()
                    
                    // delegate
                    picker.delegate = self
                    
                    // or closure
                    //        picker.didSelectEntityClosure = { name in
                    //            print(name)
                    //        }
                   self.navigationController?.pushViewController(picker, animated: true)
                })
Use this in the action of the UI element from which you want the picker to push to navigation stack.

Add this extension to your view controller :
 
     extension YourViewController: HSPickerDelegate {
    internal func entityPicker(picker: HSPicker, didSelectEntityWithName name: String) {
        selectedArray.append("\(name)")
    }
    func entityPicker(picker : HSPicker, didUnSelectEntityWithName name : String) {
        selectedArray.removeAtIndex(selectedArray.indexOf(name)!)
    }
}
 




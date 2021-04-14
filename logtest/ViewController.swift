//
//  ViewController.swift
//  logtest
//
//  Created by Inpyo Hong on 2021/04/13.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import CheckDevice

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        let db = Firestore.firestore()
//        // Add a new document with a generated ID
//        var ref: DocumentReference? = nil
//        ref = db.collection("users").addDocument(data: [
//            "first": "Ada",
//            "last": "Lovelace",
//            "born": 1815
//        ]) { err in
//            if let err = err {
//                print("Error adding document: \(err)")
//            } else {
//                print("Document added with ID: \(ref!.documentID)")
//            }
//        }
        
       removeLoggerDir()
      
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        
        print(formatter.string(from: Date()))
        self.saveLogToFile("\(formatter.string(from: Date())) log msg")
       
        guard let logMsgArr = FileManager.allRecordedLogData() else { return }
        
        print(logMsgArr[0])
        
        let pathArr = logMsgArr[0].path.split(separator: "/")
         let fileName = pathArr.last!
        print("fileName", fileName)
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let logFileDir = logMsgArr[0]
        let logFileRef = storageRef.child("appLogs/\(fileName)")
        
        var metaData: StorageMetadata {
          let metaData = StorageMetadata()
          metaData.contentType = "text/plain"
          metaData.customMetadata = [
            "Model": "\(CheckDevice.version())",
            "OS": "\(UIDevice().systemVersion)",
            "Phone": UIDevice.current.identifierForVendor!.uuidString,
            "Path": logMsgArr[0].path
          ]

          return metaData
        }

                let uploadTask = logFileRef.putFile(from: logFileDir, metadata: metaData) { metadata, error in
                  guard let metadata = metadata else {
                    // Uh-oh, an error occurred!
                    print("1 Uh-oh, an error occurred!", error)
                    return
                  }
                   //Metadata contains file metadata such as size, content-type.
                  let size = metadata.size
                    
                    print("metadata:",metadata)
                  // You can also access to download URL after upload.
                    logFileRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                      // Uh-oh, an error occurred!
                        print("2 Uh-oh, an error occurred!", error)

                      return
                    }
                    
                    print("success to upload", url)
                  }
                }
        
//        // Listen for state changes, errors, and completion of the upload.
//        uploadTask.observe(.resume) { snapshot in
//          // Upload resumed, also fires when the upload starts
//        }
//
//        uploadTask.observe(.pause) { snapshot in
//          // Upload paused
//        }
//
//        uploadTask.observe(.progress) { snapshot in
//          // Upload reported progress
//          let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
//            print("percentComplete",percentComplete)
//        }
//        uploadTask.observe(.failure) { snapshot in
//          if let error = snapshot.error as? NSError {
//            switch (StorageErrorCode(rawValue: error.code)!) {
//            case .objectNotFound:
//              // File doesn't exist
//              break
//            case .unauthorized:
//              // User doesn't have permission to access file
//              break
//            case .cancelled:
//              // User canceled the upload
//              break
//
//            /* ... */
//
//            case .unknown:
//              // Unknown error occurred, inspect the server response
//              break
//            default:
//              // A separate error occurred. This is a good place to retry the upload.
//              break
//            }
//          }
//        }
        
    }
    
    func removeLoggerDir() {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
        guard let writePath = NSURL(fileURLWithPath: path).appendingPathComponent("Logger") else { return }
        let fileManager = FileManager.default

        do {
            try fileManager.removeItem(atPath: writePath.path)
        } catch {
            print("fail to remove Logger dir")
        }
    }
    
    func saveLogToFile(_ log: String) {
        print(#function, log)
      guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
      guard let writePath = NSURL(fileURLWithPath: path).appendingPathComponent("Logger") else { return }
      let fileManager = FileManager.default

      try? fileManager.createDirectory(atPath: writePath.path, withIntermediateDirectories: true)

        guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String, let dictionary = Bundle.main.infoDictionary, let version = dictionary["CFBundleShortVersionString"] as? String, let build = dictionary["CFBundleVersion"] as? String else { return }

      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"

        let versionAndBuild: String = "\(version)(\(build))"

      let file = writePath.appendingPathComponent("iOS \(appName)(\(Bundle.main.bundleIdentifier!) [ver. \(versionAndBuild)]) \(formatter.string(from: Date())).logger")

      print(file.path)

      if !fileManager.fileExists(atPath: file.path) {
        do {
          try "".write(toFile: file.path, atomically: true, encoding: String.Encoding.utf8)
        } catch _ {
          print("fail to save Logger file!")
        }
      }

      let logWithLine = log + "\n"

      do {
        let fileHandle = try FileHandle(forWritingTo: file)
        fileHandle.seek(toFileOffset: 0)
        let oldData = try String(contentsOf: file, encoding: .utf8).data(using: .utf8)!
        var data = logWithLine.data(using: .utf8)!
        data.append(oldData)
        fileHandle.write(data)
        fileHandle.closeFile()
      } catch {
        print("Error writing to file \(error)")
      }
    }
}

extension FileManager {
    func directoryExists(_ atPath: String) -> Bool {
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: atPath, isDirectory:&isDirectory)
            return exists && isDirectory.boolValue
        }
    
  class func directoryUrl() -> URL? {
      let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      return paths.first
  }

    
    class func logDirectoryUrl() -> URL? {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return  nil}
        guard let writePath = NSURL(fileURLWithPath: path).appendingPathComponent("Logger") else { return nil }
        
        return writePath
    }
   
    
  class func allRecordedLogData() -> [URL]? {
     if let logfileUrl = FileManager.logDirectoryUrl() {
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: logfileUrl, includingPropertiesForKeys: nil)
            return directoryContents //directoryContents.filter{ $0.pathExtension == "m4a" }
        } catch {
            return nil
        }
     }
     return nil
  }}

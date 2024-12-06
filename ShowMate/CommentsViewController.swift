//
//  CommentsViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 12/6/24.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

struct Comment {
    let id: String
    let userId: String
    let username: String
    let statusId: String
    let content: String
    let timestamp: Date
    
    var toDictionary: [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "username": username,
            "statusId": statusId,
            "content": content,
            "timestamp": timestamp
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String) -> Comment? {
        guard let userId = dict["userId"] as? String,
              let username = dict["username"] as? String,
              let statusId = dict["statusId"] as? String,
              let content = dict["content"] as? String,
              let timestamp = dict["timestamp"] as? Timestamp else {
            return nil
        }
        
        return Comment(
            id: id,
            userId: userId,
            username: username,
            statusId: statusId,
            content: content,
            timestamp: timestamp.dateValue()
        )
    }
    
    static func commentsCollection() -> CollectionReference {
        return Firestore.firestore().collection("comments")
    }
}

class CommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var statusContainer: UIView!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var status: StatusUpdate!
    var statusId: String!
    private var comments: [Comment] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loadComments()
        configureStatusView()
    }
    
    private func loadComments() {
        print("Loading comments for status: \(statusId ?? "nil")")
        Comment.commentsCollection()
            .whereField("statusId", isEqualTo: statusId ?? "")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error loading comments: \(error)")
                    return
                }
                print("Found \(snapshot?.documents.count ?? 0) comments")
                self?.comments = snapshot?.documents.compactMap {
                    Comment.fromDictionary($0.data(), id: $0.documentID)
                } ?? []
                print("Parsed \(self?.comments.count ?? 0) comments")
                self?.tableView.reloadData()
            }
    }
    
    private func configureStatusView() {
        usernameLabel.text = status.username
        statusLabel.text = "S:\(status.season) E:\(status.episode)"
        messageTextView.text = status.message
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        timeLabel.text = formatter.localizedString(for: status.timestamp, relativeTo: Date())
        
        statusContainer.layer.cornerRadius = 10
    }
    
    @IBAction func postComment(_ sender: Any) {
        guard let content = commentTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !content.isEmpty,
                  let userId = Auth.auth().currentUser?.uid,
                  let username = Auth.auth().currentUser?.displayName else { return }
            
            let commentId = UUID().uuidString
            let comment = Comment(
                id: commentId,
                userId: userId,
                username: username,
                statusId: statusId,
                content: content,
                timestamp: Date()
            )
            
            // Use the generated ID when creating the document
            Comment.commentsCollection().document(commentId).setData(comment.toDictionary)
            commentTextField.text = ""
    }
    
    // UITableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
        let comment = comments[indexPath.row]
        cell.configure(with: comment)
        
        // Add border
       cell.layer.borderWidth = 1.0
       cell.layer.borderColor = UIColor.systemGray4.cgColor
       cell.layer.cornerRadius = 8
       
       // Add padding
       cell.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
       cell.separatorInset = .zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
}


class CommentCell: UITableViewCell {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    func configure(with comment: Comment) {
        usernameLabel.text = comment.username
        commentTextView.text = comment.content
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        timeLabel.text = formatter.localizedString(for: comment.timestamp, relativeTo: Date())
    }
    
    
}

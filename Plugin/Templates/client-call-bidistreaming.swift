/// {{ method.name }} (Bidirectional Streaming)
public class {{ .|call:protoFile,service,method }} {
  private var call : Call

  /// Create a call.
  fileprivate init(_ channel: Channel) {
    self.call = channel.makeCall("{{ .|path:protoFile,service,method }}")
  }

  /// Call this to start a call. Nonblocking.
  fileprivate func start(metadata:Metadata, completion:@escaping (CallResult)->())
    throws -> {{ .|call:protoFile,service,method }} {
      try self.call.start(.bidiStreaming, metadata:metadata, completion:completion)
      return self
  }

  /// Call this to wait for a result. Blocking.
  public func receive() throws -> {{ method|output }} {
    var returnError : {{ .|clienterror:protoFile,service }}?
    var returnMessage : {{ method|output }}!
    let sem = DispatchSemaphore(value: 0)
    do {
      try receive() {response, error in
        returnMessage = response
        returnError = error
        sem.signal()
      }
      _ = sem.wait(timeout: DispatchTime.distantFuture)
    }
    if let returnError = returnError {
      throw returnError
    }
    return returnMessage
  }

  /// Call this to wait for a result. Nonblocking.
  public func receive(completion:@escaping ({{ method|output }}?, {{ .|clienterror:protoFile,service }}?)->()) throws {
    do {
      try call.receiveMessage() {(data) in
        if let data = data {
          if let returnMessage = try? {{ method|output }}(protobuf:data) {
            completion(returnMessage, nil)
          } else {
            completion(nil, {{ .|clienterror:protoFile,service }}.invalidMessageReceived)
          }
        } else {
          completion(nil, {{ .|clienterror:protoFile,service }}.endOfStream)
        }
      }
    }
  }

  /// Call this to send each message in the request stream.
  public func send(_ message:Echo_EchoRequest, errorHandler:@escaping (Error)->()) throws {
    let messageData = try message.serializeProtobuf()
    try call.sendMessage(data:messageData, errorHandler:errorHandler)
  }

  /// Call this to close the sending connection. Blocking.
  public func closeSend() throws {
    let sem = DispatchSemaphore(value: 0)
    try closeSend() {
      sem.signal()
    }
    _ = sem.wait(timeout: DispatchTime.distantFuture)
  }

  /// Call this to close the sending connection. Nonblocking.
  public func closeSend(completion:@escaping ()->()) throws {
    try call.close() {
      completion()
    }
  }
}
